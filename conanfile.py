import glob
import os
import re
from conans import ConanFile, AutoToolsBuildEnvironment, RunEnvironment, CMake, tools
from conans.errors import ConanInvalidConfiguration

class Krb5Conan(ConanFile):
    name = "krb5"
    version = "1.22.0-beta1+0"
    description = "kerberos 5 library"
    topics = ("krb5", "kerberos")
    url = "https://github.com/krb5/krb5"
    homepage = "https://web.mit.edu/kerberos/"
    license = "MIT"
    settings = "os", "arch", "compiler", "build_type"
    options = {
        "dll_sign": [False, True],
    }
    default_options = "dll_sign=True"
    exports_sources = ["src/*"]
    no_copy_source = False
    build_policy = "missing"

    _autotools = None

    def configure(self):
        # DLL sign
        if self.settings.os != "Windows":
            del self.options.dll_sign
        # Pure C library
        del self.settings.compiler.libcxx
        del self.settings.compiler.cppstd

    def build_requirements(self):
        if self.options.get_safe("dll_sign"):
            self.build_requires("windows_signtool/[~=1.1]@%s/stable" % self.user)
            
    def requirements(self):
        self.requires("openssl/3.0.13+0@odant/stable")
    
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

            env_run = RunEnvironment(self)
            # run configure with *LD_LIBRARY_PATH env vars it allows to pick up shared openssl
            self.output.info("Run vars: " + repr(env_run.vars))
            with tools.environment_append(env_run.vars):
                autotools = self._configure_autotools()
                autotools.make()


    def windows_build(self):
        raise RuntimeError('Not implemented')
        
    def _configure_autotools(self):
        if self._autotools:
            return self._autotools

        self._autotools = AutoToolsBuildEnvironment(self, win_bash=tools.os_info.is_windows)

        if self.settings.os != "Windows":
            self._autotools.fpic = True

        self._autotools.configure()

        return self._autotools
        
    def package(self):
        env_run = RunEnvironment(self)
        with tools.environment_append(env_run.vars):
            with tools.chdir("src"):
                autotools = self._configure_autotools()
                autotools.install()
        tools.rmdir(os.path.join(self.package_folder, "share"))
        tools.rmdir(os.path.join(self.package_folder, "var"))
        tools.rmdir(os.path.join(self.package_folder, "lib", "pkgconfig"))
        tools.rmdir(os.path.join(self.package_folder, "lib", "krb5"))
    
    def package_info(self):
        self.cpp_info.names["cmake_find_package"] = self.name
        self.cpp_info.libs = tools.collect_libs(self)            