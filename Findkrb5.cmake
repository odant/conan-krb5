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

find_library(KRB5_COM_ERR_LIBRARY
    NAMES com_err
    PATHS ${CONAN_LIB_DIRS_KRB5}
    NO_DEFAULT_PATH
)

find_library(KRB5_GSSAPI_KRB5_LIBRARY
    NAMES gssapi_krb5
    PATHS ${CONAN_LIB_DIRS_KRB5}
    NO_DEFAULT_PATH
)

find_library(KRB5_GSSRPC_LIBRARY
    NAMES gssrpc
    PATHS ${CONAN_LIB_DIRS_KRB5}
    NO_DEFAULT_PATH
)

find_library(KRB5_K5CRYPTO_LIBRARY
    NAMES k5crypto
    PATHS ${CONAN_LIB_DIRS_KRB5}
    NO_DEFAULT_PATH
)

find_library(KRB5_KADM5CLNT_MIT_LIBRARY
    NAMES kadm5clnt_mit
    PATHS ${CONAN_LIB_DIRS_KRB5}
    NO_DEFAULT_PATH
)

find_library(KRB5_KADM5CLNT_LIBRARY
    NAMES kadm5clnt
    PATHS ${CONAN_LIB_DIRS_KRB5}
    NO_DEFAULT_PATH
)

find_library(KRB5_KADM5SRV_MIT_LIBRARY
    NAMES kadm5srv_mit
    PATHS ${CONAN_LIB_DIRS_KRB5}
    NO_DEFAULT_PATH
)

find_library(KRB5_KADM5SRV_LIBRARY
    NAMES kadm5srv
    PATHS ${CONAN_LIB_DIRS_KRB5}
    NO_DEFAULT_PATH
)

find_library(KRB5_KDB5_LIBRARY
    NAMES kdb5
    PATHS ${CONAN_LIB_DIRS_KRB5}
    NO_DEFAULT_PATH
)

find_library(KRB5_KRAD_LIBRARY
    NAMES krad
    PATHS ${CONAN_LIB_DIRS_KRB5}
    NO_DEFAULT_PATH
)

find_library(KRB5_KRB5SUPPORT_LIBRARY
    NAMES krb5support
    PATHS ${CONAN_LIB_DIRS_KRB5}
    NO_DEFAULT_PATH
)

find_library(KRB5_VERTO_LIBRARY
    NAMES verto
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
    REQUIRED_VARS
        KRB5_INCLUDE_DIR
        KRB5_LIBRARY
        KRB5_COM_ERR_LIBRARY
        KRB5_GSSAPI_KRB5_LIBRARY
        KRB5_GSSRPC_LIBRARY
        KRB5_K5CRYPTO_LIBRARY
        KRB5_KADM5CLNT_MIT_LIBRARY
        KRB5_KADM5CLNT_LIBRARY
        KRB5_KADM5SRV_MIT_LIBRARY
        KRB5_KADM5SRV_LIBRARY
        KRB5_KDB5_LIBRARY
        KRB5_KRAD_LIBRARY
        KRB5_KRB5SUPPORT_LIBRARY
        KRB5_VERTO_LIBRARY
    VERSION_VAR
        KRB5_VERSION_STRING
)

if(krb5_FOUND)
    set(KRB5_INCLUDE_DIRS ${KRB5_INCLUDE_DIR})
    set(KRB5_LIBRARIES 
            ${KRB5_LIBRARY}
            ${KRB5_COM_ERR_LIBRARY}
            ${KRB5_GSSAPI_KRB5_LIBRARY}
            ${KRB5_GSSRPC_LIBRARY}
            ${KRB5_K5CRYPTO_LIBRARY}
            ${KRB5_KADM5CLNT_MIT_LIBRARY}
            ${KRB5_KADM5CLNT_LIBRARY}
            ${KRB5_KADM5SRV_MIT_LIBRARY}
            ${KRB5_KADM5SRV_LIBRARY}
            ${KRB5_KDB5_LIBRARY}
            ${KRB5_KRAD_LIBRARY}
            ${KRB5_KRB5SUPPORT_LIBRARY}
            ${KRB5_VERTO_LIBRARY}
    )
    mark_as_advanced(KRB5_INCLUDE_DIR KRB5_LIBRARY KRB5_COM_ERR_LIBRARY KRB5_GSSAPI_KRB5_LIBRARY
                     KRB5_GSSRPC_LIBRARY KRB5_K5CRYPTO_LIBRARY KRB5_KADM5CLNT_MIT_LIBRARY
                     KRB5_KADM5CLNT_LIBRARY KRB5_KADM5SRV_MIT_LIBRARY KRB5_KADM5SRV_LIBRARY
                     KRB5_KDB5_LIBRARY KRB5_KRAD_LIBRARY KRB5_KRB5SUPPORT_LIBRARY KRB5_VERTO_LIBRARY)
    
    if(NOT TARGET krb5::krb5support)
        add_library(krb5::krb5support UNKNOWN IMPORTED)
        set_target_properties(krb5::krb5support PROPERTIES
            IMPORTED_LOCATION "${KRB5_KRB5SUPPORT_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${KRB5_INCLUDE_DIR}"
        )
    endif()

    if(NOT TARGET krb5::verto)
        add_library(krb5::verto UNKNOWN IMPORTED)
        set_target_properties(krb5::verto PROPERTIES
            IMPORTED_LOCATION "${KRB5_VERTO_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${KRB5_INCLUDE_DIR}"
        )
    endif()

    if(NOT TARGET krb5::com_err)
        add_library(krb5::com_err UNKNOWN IMPORTED)
        set_target_properties(krb5::com_err PROPERTIES
            IMPORTED_LOCATION "${KRB5_COM_ERR_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${KRB5_INCLUDE_DIR}"
            INTERFACE_LINK_LIBRARIES "krb5::krb5support"
        )
    endif()
  
    if(NOT TARGET krb5::k5crypto)
        add_library(krb5::k5crypto UNKNOWN IMPORTED)
        set_target_properties(krb5::k5crypto PROPERTIES
            IMPORTED_LOCATION "${KRB5_K5CRYPTO_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${KRB5_INCLUDE_DIR}"
            INTERFACE_LINK_LIBRARIES "krb5::krb5support"
        )
    endif()

    if(NOT TARGET krb5::krb5)
        add_library(krb5::krb5 UNKNOWN IMPORTED)
        set_target_properties(krb5::krb5 PROPERTIES
            IMPORTED_LOCATION "${KRB5_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${KRB5_INCLUDE_DIR}"
            INTERFACE_LINK_LIBRARIES "krb5::k5crypto;krb5::com_err;krb5::krb5support"
        )
    endif()

    if(NOT TARGET krb5::gssapi)
        add_library(krb5::gssapi UNKNOWN IMPORTED)
        set_target_properties(krb5::gssapi PROPERTIES
            IMPORTED_LOCATION "${KRB5_GSSAPI_KRB5_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${KRB5_INCLUDE_DIR}"
            INTERFACE_LINK_LIBRARIES "krb5::krb5"
        )
    endif()
    
    if(NOT TARGET krb5::gssrpc)
        add_library(krb5::gssrpc UNKNOWN IMPORTED)
        set_target_properties(krb5::gssrpc PROPERTIES
            IMPORTED_LOCATION "${KRB5_GSSRPC_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${KRB5_INCLUDE_DIR}"
            INTERFACE_LINK_LIBRARIES "krb5::gssapi_krb5"
        )
    endif()

    if(NOT TARGET krb5::kadm5clnt_mit)
        add_library(krb5::kadm5clnt_mit UNKNOWN IMPORTED)
        set_target_properties(krb5::kadm5clnt_mit PROPERTIES
            IMPORTED_LOCATION "${KRB5_KADM5CLNT_MIT_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${KRB5_INCLUDE_DIR}"
            INTERFACE_LINK_LIBRARIES "krb5::gssrpc"
        )
    endif()

    if(NOT TARGET krb5::kadm5clnt)
        add_library(krb5::kadm5clnt UNKNOWN IMPORTED)
        set_target_properties(krb5::kadm5clnt PROPERTIES
            IMPORTED_LOCATION "${KRB5_KADM5CLNT_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${KRB5_INCLUDE_DIR}"
            INTERFACE_LINK_LIBRARIES "krb5::gssrpc"
        )
    endif()

    if(NOT TARGET krb5::kdb5)
        add_library(krb5::kdb5 UNKNOWN IMPORTED)
        set_target_properties(krb5::kdb5 PROPERTIES
            IMPORTED_LOCATION "${KRB5_KDB5_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${KRB5_INCLUDE_DIR}"
            INTERFACE_LINK_LIBRARIES "krb5::gssrpc"
        )
    endif()

    if(NOT TARGET krb5::kadm5srv_mit)
        add_library(krb5::kadm5srv_mit UNKNOWN IMPORTED)
        set_target_properties(krb5::kadm5srv_mit PROPERTIES
            IMPORTED_LOCATION "${KRB5_KADM5SRV_MIT_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${KRB5_INCLUDE_DIR}"
            INTERFACE_LINK_LIBRARIES "krb5::kdb5"
        )
    endif()

    if(NOT TARGET krb5::kadm5srv)
        add_library(krb5::kadm5srv UNKNOWN IMPORTED)
        set_target_properties(krb5::kadm5srv PROPERTIES
            IMPORTED_LOCATION "${KRB5_KADM5SRV_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${KRB5_INCLUDE_DIR}"
            INTERFACE_LINK_LIBRARIES "krb5::kdb5"
        )
    endif()

    if(NOT TARGET krb5::krad)
        add_library(krb5::krad UNKNOWN IMPORTED)
        set_target_properties(krb5::krad PROPERTIES
            IMPORTED_LOCATION "${KRB5_KRAD_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${KRB5_INCLUDE_DIR}"
            INTERFACE_LINK_LIBRARIES "krb5::krb5;krb5::verto"
        )
    endif()

endif()
