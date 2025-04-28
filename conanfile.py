from conan import ConanFile, tools
from conan.tools.gnu import Autotools, AutotoolsDeps, AutotoolsToolchain 
from conan.errors import ConanInvalidConfiguration
from datetime import datetime
from conan.tools.layout import basic_layout
import os

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
    version = "1.22.0-beta3+0"
    description = "kerberos 5 library"
    topics = ("krb5", "kerberos")
    url = "https://github.com/krb5/krb5"
    homepage = "https://web.mit.edu/kerberos/"
    license = "MIT"
    settings = "os", "arch", "compiler", "build_type"
    options = {
        "fPIC": [False, True]
    }
    default_options = {
        "fPIC": True
    }
    exports_sources = ["src/*"]
    no_copy_source = False
    build_policy = "missing"
    package_type = "shared-library"
    
    def layout(self):
        basic_layout(self, src_folder="src")

    def configure(self):
        # Pure C library
        self.settings.rm_safe("compiler.cppstd")
        self.settings.rm_safe("compiler.libcxx")

    def requirements(self):
        self.requires("openssl/[>=3.0]@odant/stable")
    
    def generate(self):
        benv = tools.env.VirtualBuildEnv(self)
        benv.generate()
        renv = tools.env.VirtualRunEnv(self)
        renv.generate()
        tc = tools.gnu.AutotoolsToolchain(self)
        tc.configure_args.extend([
          "--without-system-verto"
        ])
        tc.generate()
        deps = tools.gnu.AutotoolsDeps(self)
        deps.generate()
        
    def build(self):
        #
        self.output.info("--------------Start build--------------")
        # autoreconf
        with tools.files.chdir(self, self.source_folder):
            env = tools.env.Environment()
            self.run("{} -fiv".format(env.vars(self, scope="run").get("AUTORECONF") or "autoreconf"))
            self.run("chmod +x configure")
        autotools = tools.gnu.Autotools(self)
        autotools.configure()
        autotools.make()
        self.output.info("--------------Build done---------------")
       
    def package(self):
        autotools = tools.gnu.Autotools(self)
        autotools.install()
        # remove unused folders
        tools.files.rmdir(self, os.path.join(self.package_folder, "share"))
        tools.files.rmdir(self, os.path.join(self.package_folder, "var"))
        tools.files.rmdir(self, os.path.join(self.package_folder, "lib", "pkgconfig"))
        tools.files.rmdir(self, os.path.join(self.package_folder, "lib", "krb5"))
        # generate krb5_version.h
        version_h = generateVersionH(self.version)
        tools.files.save(self, os.path.join(self.package_folder, "include", "krb5_version.h"), version_h)                
    
    def package_info(self):
        self.cpp_info.components["krb5"].libs = ["krb5"]
        self.cpp_info.components["krb5"].requires = ["k5crypto", "com_err", "krb5support", "openssl::crypto"]
        if self.settings.os == "Linux":
            self.cpp_info.components["krb5"].system_libs = ["resolv"]

        self.cpp_info.components["com_err"].libs = ["com_err"]
        self.cpp_info.components["com_err"].requires = ["krb5support"]

        self.cpp_info.components["gssapi"].libs = ["gssapi_krb5"]
        self.cpp_info.components["gssapi"].requires = ["krb5"]

        self.cpp_info.components["gssrpc"].libs = ["gssrpc"]
        self.cpp_info.components["gssrpc"].requires = ["gssapi"]

        self.cpp_info.components["k5crypto"].libs = ["k5crypto"]
        self.cpp_info.components["k5crypto"].requires = ["krb5support"]

        self.cpp_info.components["kadm5clnt"].libs = ["kadm5clnt"]
        self.cpp_info.components["kadm5clnt"].requires = ["gssrpc"]

        self.cpp_info.components["kadm5clnt_mit"].libs = ["kadm5clnt_mit"]
        self.cpp_info.components["kadm5clnt_mit"].requires = ["gssrpc"]

        self.cpp_info.components["kadm5srv_mit"].libs = ["kadm5srv_mit"]
        self.cpp_info.components["kadm5srv_mit"].requires = ["kdb5"]

        self.cpp_info.components["kadm5srv"].libs = ["kadm5srv"]
        self.cpp_info.components["kadm5srv"].requires = ["kdb5"]

        self.cpp_info.components["kdb5"].libs = ["kdb5"]
        self.cpp_info.components["kdb5"].requires = ["gssrpc"]

        self.cpp_info.components["krad"].libs = ["krad"]
        self.cpp_info.components["krad"].requires = ["krb5", "verto"]

        self.cpp_info.components["krb5support"].libs = ["krb5support"]
        self.cpp_info.components["krb5support"].requires = []

        self.cpp_info.components["verto"].libs = ["verto"]
        self.cpp_info.components["verto"].requires = []
        
