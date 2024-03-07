import os
from conans import ConanFile, AutoToolsBuildEnvironment, RunEnvironment, tools
from conans.errors import ConanInvalidConfiguration
from datetime import datetime

def generateVersionH(originalVersion, current_time=datetime.now()):
    coreVersion = originalVersion
    byPlus = coreVersion.split('+')
    byPlusCount = len(byPlus)
    modifyVersion = None
    if byPlusCount > 2:
        raise ValueError("There are too many separators +");
    elif byPlusCount == 2:
        coreVersion = byPlus[0]
        modifyVersion = byPlus[1]
    byMinus = coreVersion.split('-')
    byMinusCount = len(byMinus)
    prereleaseVersion = None
    if byMinusCount > 2:
        raise ValueError("There are too many separators -");
    elif byMinusCount == 2:
        coreVersion = byMinus[0]
        prereleaseVersion = byMinus[1]

    coreVersionParts = coreVersion.split('.');
    coreVersionPartsCount = len(coreVersionParts)
    if coreVersionPartsCount < 2 or coreVersionPartsCount > 4:
        raise ValueError("Error in the version core format");

    content = ""
    content += "#ifndef KRB5_VERSIONNO__H\n"
    content += "#define KRB5_VERSIONNO__H\n"
    content += "\n"
    content += "#define KRB5_VERSION_FULL           " + originalVersion + "\n"
    content += "\n"
    if prereleaseVersion is not None:
        content += "#define KRB5_PRERELEAS              true\n"
        content += "#define KRB5_PRERELEAS_VERSION      \"" + prereleaseVersion + "\"\n"
    else:    
        content += "#define KRB5_PRERELEAS              false\n"
    content += "\n"
    content += "#define KRB5_VERSION_PARTS_COUNT    " + str(coreVersionPartsCount) + "\n"
    content += "\n"
    content += "#define KRB5_VERSION_MAJOR          " + coreVersionParts[0] + "\n"
    content += "#define KRB5_VERSION_MINOR          " + coreVersionParts[1] + "\n"
    if coreVersionPartsCount > 2:
        content += "#define KRB5_VERSION_PATCH          " + coreVersionParts[2] + "\n"
    if coreVersionPartsCount > 3:
        content += "#define KRB5_VERSION_BUILD          " + coreVersionParts[3] + "\n"
    if modifyVersion is not None:
        content += "#define KRB5_VERSION_MODIFY         " + str(modifyVersion) + "\n"
    content += "\n"
    content += "#define KRB5_VERSION_DATE           " + "\"" + current_time.strftime("%Y-%m-%d") + "\"\n"
    content += "#define KRB5_VERSION_TIME           " + "\"" + current_time.strftime("%H:%M:%S") + "\"\n"
    content += "\n"
    content += "#define KRB5_VERSION_FILE           " + coreVersion.replace(".", ",") + "\n"
    content += "#define KRB5_VERSION_PRODUCT        " + coreVersion.replace(".", ",") + "\n"
    content += "#define KRB5_VERSION_FILESTR        " + "\"" + originalVersion + "\"\n"
    content += "#define KRB5_VERSION_PRODUCTSTR     " + "\"" + coreVersionParts[0] + '.' + coreVersionParts[1] + "\"\n"
    content += "\n"
    content += "#endif\t// KRB5_VERSIONNO__H\n"
    return content
    
class Krb5Conan(ConanFile):
    name = "krb5"
    version = "1.22.0-beta1+1"
    description = "kerberos 5 library"
    topics = ("krb5", "kerberos")
    url = "https://github.com/krb5/krb5"
    homepage = "https://web.mit.edu/kerberos/"
    license = "MIT"
    settings = "os", "arch", "compiler", "build_type"
    options = {
        "fPIC": [False, True],
        "dll_sign": [False, True]
    }
    default_options = {
        "dll_sign": True,
        "fPIC": True
    }
    exports_sources = ["src/*", "Findkrb5.cmake"]
    no_copy_source = False
    build_policy = "missing"

    _autotools = None

    def configure(self):
        if self.settings.os == "Windows":
            self.options.rm_safe("fPIC")
        else:
            self.options.rm_safe("dll_sign")
        # Pure C library
        self.settings.rm_safe("compiler.cppstd")
        self.settings.rm_safe("compiler.libcxx")

    def build_requirements(self):
        if self.options.get_safe("dll_sign"):
            self.build_requires("windows_signtool/[~=1.1]@%s/stable" % self.user)
            
    def requirements(self):
        self.requires("openssl/[>=3.0]@odant/stable")
    
    def build(self):
        #
        self.output.info("--------------Start build--------------")
        if self.settings.os == "Windows" and self.settings.compiler == "Visual Studio":
            self.windows_build()
        else:
            self.posix_build()
        self.output.info("--------------Build done---------------")
    
    def posix_build(self):
        with tools.chdir("src"):
            # autoreconf
            self.run("{} -fiv".format(tools.get_env("AUTORECONF") or "autoreconf"), win_bash=tools.os_info.is_windows, run_environment=True)
            self.run("chmod +x configure")
            env = {}
            # run configure with *LD_LIBRARY_PATH env vars it allows to pick up shared openssl
            env.update(RunEnvironment(self).vars)
            # clear c++ compiler environment variables
            env.update({"CXX":"", "CPP":""})
            self.output.info("Set environment vars: " + repr(env))
            with tools.environment_append(env):
                autotools = self._configure_autotools()
                autotools.make()


    def windows_build(self):
        raise RuntimeError('Not implemented')
        
    def _configure_autotools(self):
        if self._autotools:
            return self._autotools

        self._autotools = AutoToolsBuildEnvironment(self, win_bash=tools.os_info.is_windows)

        if self.options.get_safe("fPIC"):
            self._autotools.fpic = True
        
        params = [
            "--with-system-verto=no"       
        ]
        self._autotools.configure(args=params)

        return self._autotools
        
    def package(self):
        self.copy("Findkrb5.cmake", src=".", dst=".")

        env_run = RunEnvironment(self)
        with tools.environment_append(env_run.vars):
            with tools.chdir("src"):
                autotools = self._configure_autotools()
                autotools.install()
        # remove unused folders
        tools.rmdir(os.path.join(self.package_folder, "share"))
        tools.rmdir(os.path.join(self.package_folder, "var"))
        tools.rmdir(os.path.join(self.package_folder, "lib", "pkgconfig"))
        tools.rmdir(os.path.join(self.package_folder, "lib", "krb5"))
        # generate krb5_version.h
        version_h = generateVersionH(self.version)
        tools.save(os.path.join(self.package_folder, "include", "krb5_version.h"), version_h)                
    
    def package_info(self):
        self.cpp_info.libs = tools.collect_libs(self)
