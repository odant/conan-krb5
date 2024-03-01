find_path(KRB5_INCLUDE_DIR
    NAMES krb5.h
    PATHS ${CONAN_INCLUDE_DIRS_KRB5}
    NO_DEFAULT_PATH
)

find_library(KRB5_LIBRARY
    NAMES krb5
    PATHS ${CONAN_LIB_DIRS_KRB5}
    NO_DEFAULT_PATH
)

if(KRB5_INCLUDE_DIR AND EXISTS "${KRB5_INCLUDE_DIR}/krb5_version.h")
    file(STRINGS "${KRB5_INCLUDE_DIR}/krb5_version.h" DEFINE_KRB5_MAJOR_VERSION REGEX "^[ \\t]*#[ \\t]*define[ \\t]+KRB5_VERSION_MAJOR[ \\t]+")
    string(REGEX REPLACE "^[ \\t]*#[ \\t]*define[ \\t]+KRB5_VERSION_MAJOR[ \\t]+([0-9]+).*$" "\\1" KRB5_VERSION_MAJOR "${DEFINE_KRB5_MAJOR_VERSION}")

    file(STRINGS "${KRB5_INCLUDE_DIR}/krb5_version.h" DEFINE_KRB5_MINOR_VERSION REGEX "^[ \\t]*#[ \\t]*define[ \\t]+KRB5_VERSION_MINOR[ \\t]+")
    string(REGEX REPLACE "^[ \\t]*#[ \\t]*define[ \\t]+KRB5_VERSION_MINOR[ \\t]+([0-9]+).*$" "\\1" KRB5_VERSION_MINOR "${DEFINE_KRB5_MINOR_VERSION}")

    file(STRINGS "${KRB5_INCLUDE_DIR}/krb5_version.h" DEFINE_KRB5_PATCH_VERSION REGEX "^[ \\t]*#[ \\t]*define[ \\t]+KRB5_VERSION_PATCH[ \\t]+")
    string(REGEX REPLACE "^[ \\t]*#[ \\t]*define[ \\t]+KRB5_VERSION_PATCH[ \\t]+([0-9]+).*$" "\\1" KRB5_VERSION_PATCH "${DEFINE_KRB5_PATCH_VERSION}")

    set(KRB5_VERSION_STRING "${KRB5_VERSION_MAJOR}.${KRB5_VERSION_MINOR}.${KRB5_VERSION_PATCH}")
    set(KRB5_VERSION ${KRB5_VERSION_STRING})
    set(KRB5_VERSION_COUNT 3)
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(krb5
    REQUIRED_VARS KRB5_INCLUDE_DIR KRB5_LIBRARY
    VERSION_VAR KRB5_VERSION_STRING
)

if(krb5_FOUND AND NOT TARGET krb5::krb5)
    add_library(krb5::krb5 UNKNOWN IMPORTED)
    set_target_properties(krb5::krb5 PROPERTIES
        IMPORTED_LOCATION "${KRB5_LIBRARY}"
        INTERFACE_INCLUDE_DIRECTORIES "${KRB5_INCLUDE_DIR}"
    )
    
    mark_as_advanced(KRB5_INCLUDE_DIR KRB5_LIBRARY)
    set(KRB5_INCLUDE_DIRS ${KRB5_INCLUDE_DIR})
    set(KRB5_LIBRARIES ${KRB5_LIBRARY})
endif()
