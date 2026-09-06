/**
 *  Copyright (c) 1999~2017, Altibase Corp. and/or its affiliates. All rights reserved.
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Lesser General Public License, version 3,
 *  as published by the Free Software Foundation.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *  GNU Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public License
 *  along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

#include <cm.h>
#include <cmnOpenssl.h>

#if !defined(CM_DISABLE_SSL)

PDL_SHLIB_HANDLE cmnOpenssl::mSslHandle;
PDL_SHLIB_HANDLE cmnOpenssl::mCryptoHandle;
cmnOpensslFuncs  cmnOpenssl::mFuncs;
idBool           cmnOpenssl::mLibInitialized = ID_FALSE;

IDE_RC cmnOpenssl::initialize()
{
    SChar sOpensslSoName[1024];
    SChar sCryptoSoName[1024];

    idlOS::sprintf(sOpensslSoName, "%s%s%s", PDL_DLL_PREFIX, ALTIBASE_OPENSSL_LIB_NAME, PDL_DLL_SUFFIX);
    idlOS::sprintf(sCryptoSoName, "%s%s%s", PDL_DLL_PREFIX, ALTIBASE_CRYPTO_LIB_NAME, PDL_DLL_SUFFIX);

    /* RTDL_LAZY: Only resolve symbols as the code that references them is executed.
     * RTLD_LOCAL: Symbols of the openssl library are not made available
     *             to resolve references in subsequently loaded libraries. */
    mSslHandle = idlOS::dlopen(sOpensslSoName, RTLD_LAZY | RTLD_LOCAL);
    IDE_TEST_RAISE(mSslHandle == PDL_SHLIB_INVALID_HANDLE, ERR_DLOPEN_LIBSSL);

    mCryptoHandle = idlOS::dlopen(sCryptoSoName, RTLD_LAZY | RTLD_LOCAL);
    IDE_TEST_RAISE(mCryptoHandle == PDL_SHLIB_INVALID_HANDLE, ERR_DLOPEN_LIBCRYPTO);

    /* load functions */

    *(void**)&mFuncs.SSL_CTX_new = idlOS::dlsym(mSslHandle, "SSL_CTX_new");
    IDE_TEST_RAISE(mFuncs.SSL_CTX_new == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&mFuncs.TLS_server_method = idlOS::dlsym(mSslHandle, "TLS_server_method");
    IDE_TEST_RAISE(mFuncs.TLS_server_method == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&mFuncs.TLS_client_method = idlOS::dlsym(mSslHandle, "TLS_client_method");
    IDE_TEST_RAISE(mFuncs.TLS_client_method == NULL, ERR_DLSYM_LIBSSL);

#if (DEBUG)  /* BUG-47037 OPENSSL_VERSION_NUMBER >= 0x00909000L */
    /* This function can be null depending on the library version
     * and is used only for debugging. */
    *(void**)&mFuncs.SSL_CTX_set_info_callback = idlOS::dlsym(mSslHandle, "SSL_CTX_set_info_callback");
#endif

    *(void**)&mFuncs.SSL_CTX_use_certificate_file = idlOS::dlsym(mSslHandle, "SSL_CTX_use_certificate_file");
    IDE_TEST_RAISE(mFuncs.SSL_CTX_use_certificate_file == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&mFuncs.SSL_CTX_set_default_passwd_cb = idlOS::dlsym(mSslHandle, "SSL_CTX_set_default_passwd_cb");
    IDE_TEST_RAISE(mFuncs.SSL_CTX_set_default_passwd_cb == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&mFuncs.SSL_CTX_use_PrivateKey_file = idlOS::dlsym(mSslHandle, "SSL_CTX_use_PrivateKey_file");
    IDE_TEST_RAISE(mFuncs.SSL_CTX_use_PrivateKey_file == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&mFuncs.SSL_CTX_check_private_key = idlOS::dlsym(mSslHandle, "SSL_CTX_check_private_key");
    IDE_TEST_RAISE(mFuncs.SSL_CTX_check_private_key == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&mFuncs.SSL_CTX_set_cipher_list = idlOS::dlsym(mSslHandle, "SSL_CTX_set_cipher_list");
    IDE_TEST_RAISE(mFuncs.SSL_CTX_set_cipher_list == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&mFuncs.SSL_get_current_cipher = idlOS::dlsym(mSslHandle, "SSL_get_current_cipher");
    IDE_TEST_RAISE(mFuncs.SSL_get_current_cipher == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&mFuncs.SSL_CIPHER_get_name = idlOS::dlsym(mSslHandle, "SSL_CIPHER_get_name");
    IDE_TEST_RAISE(mFuncs.SSL_CIPHER_get_name == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&mFuncs.SSL_CTX_set_verify_depth = idlOS::dlsym(mSslHandle, "SSL_CTX_set_verify_depth");
    IDE_TEST_RAISE(mFuncs.SSL_CTX_set_verify_depth == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&mFuncs.SSL_CTX_load_verify_locations = idlOS::dlsym(mSslHandle, "SSL_CTX_load_verify_locations");
    IDE_TEST_RAISE(mFuncs.SSL_CTX_load_verify_locations == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&mFuncs.SSL_CTX_set_default_verify_paths = idlOS::dlsym(mSslHandle, "SSL_CTX_set_default_verify_paths");
    IDE_TEST_RAISE(mFuncs.SSL_CTX_set_default_verify_paths == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&mFuncs.SSL_CTX_ctrl = idlOS::dlsym(mSslHandle, "SSL_CTX_ctrl");
    IDE_TEST_RAISE(mFuncs.SSL_CTX_ctrl == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&mFuncs.SSL_CTX_set_client_CA_list = idlOS::dlsym(mSslHandle, "SSL_CTX_set_client_CA_list");
    IDE_TEST_RAISE(mFuncs.SSL_CTX_set_client_CA_list == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&mFuncs.SSL_CTX_set_verify = idlOS::dlsym(mSslHandle, "SSL_CTX_set_verify");
    IDE_TEST_RAISE(mFuncs.SSL_CTX_set_verify == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&mFuncs.SSL_CTX_free = idlOS::dlsym(mSslHandle, "SSL_CTX_free");
    IDE_TEST_RAISE(mFuncs.SSL_CTX_free == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&mFuncs.SSL_set_quiet_shutdown = idlOS::dlsym(mSslHandle, "SSL_set_quiet_shutdown");
    IDE_TEST_RAISE(mFuncs.SSL_set_quiet_shutdown == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&mFuncs.SSL_get1_peer_certificate = idlOS::dlsym(mSslHandle, "SSL_get1_peer_certificate");
    IDE_TEST_RAISE(mFuncs.SSL_get1_peer_certificate == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&mFuncs.SSL_get_verify_result = idlOS::dlsym(mSslHandle, "SSL_get_verify_result");
    IDE_TEST_RAISE(mFuncs.SSL_get_verify_result == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&mFuncs.SSL_load_client_CA_file = idlOS::dlsym(mSslHandle, "SSL_load_client_CA_file");
    IDE_TEST_RAISE(mFuncs.SSL_load_client_CA_file == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&mFuncs.SSL_set_cipher_list = idlOS::dlsym(mSslHandle, "SSL_set_cipher_list");
    IDE_TEST_RAISE(mFuncs.SSL_set_cipher_list == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&mFuncs.SSL_shutdown = idlOS::dlsym(mSslHandle, "SSL_shutdown");
    IDE_TEST_RAISE(mFuncs.SSL_shutdown == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&mFuncs.SSL_free = idlOS::dlsym(mSslHandle, "SSL_free");
    IDE_TEST_RAISE(mFuncs.SSL_free == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&mFuncs.SSL_get_error = idlOS::dlsym(mSslHandle, "SSL_get_error");
    IDE_TEST_RAISE(mFuncs.SSL_get_error == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&mFuncs.ERR_error_string = idlOS::dlsym(mSslHandle, "ERR_error_string");
    IDE_TEST_RAISE(mFuncs.ERR_error_string == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&mFuncs.ERR_get_error = idlOS::dlsym(mSslHandle, "ERR_get_error");
    IDE_TEST_RAISE(mFuncs.ERR_get_error == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&mFuncs.SSL_read = idlOS::dlsym(mSslHandle, "SSL_read");
    IDE_TEST_RAISE(mFuncs.SSL_read == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&mFuncs.SSL_write = idlOS::dlsym(mSslHandle, "SSL_write");
    IDE_TEST_RAISE(mFuncs.SSL_write == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&mFuncs.SSL_new = idlOS::dlsym(mSslHandle, "SSL_new");
    IDE_TEST_RAISE(mFuncs.SSL_new == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&mFuncs.SSL_connect = idlOS::dlsym(mSslHandle, "SSL_connect");
    IDE_TEST_RAISE(mFuncs.SSL_connect == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&mFuncs.SSL_set_fd = idlOS::dlsym(mSslHandle, "SSL_set_fd");
    IDE_TEST_RAISE(mFuncs.SSL_set_fd == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&mFuncs.SSL_accept = idlOS::dlsym(mSslHandle, "SSL_accept");
    IDE_TEST_RAISE(mFuncs.SSL_accept == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&mFuncs.SSL_state_string_long = idlOS::dlsym(mSslHandle, "SSL_state_string_long");
    IDE_TEST_RAISE(mFuncs.SSL_state_string_long == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&mFuncs.SSL_alert_type_string_long = idlOS::dlsym(mSslHandle, "SSL_alert_type_string_long");
    IDE_TEST_RAISE(mFuncs.SSL_alert_type_string_long == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&mFuncs.SSL_alert_desc_string_long = idlOS::dlsym(mSslHandle, "SSL_alert_desc_string_long");
    IDE_TEST_RAISE(mFuncs.SSL_alert_desc_string_long == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&mFuncs.X509_NAME_oneline = idlOS::dlsym(mSslHandle, "X509_NAME_oneline");
    IDE_TEST_RAISE(mFuncs.X509_NAME_oneline == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&mFuncs.X509_get_subject_name = idlOS::dlsym(mSslHandle, "X509_get_subject_name");
    IDE_TEST_RAISE(mFuncs.X509_get_subject_name == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&mFuncs.X509_get_issuer_name = idlOS::dlsym(mSslHandle, "X509_get_issuer_name");
    IDE_TEST_RAISE(mFuncs.X509_get_issuer_name == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&mFuncs.X509_NAME_get_text_by_NID = idlOS::dlsym(mSslHandle, "X509_NAME_get_text_by_NID");
    IDE_TEST_RAISE(mFuncs.X509_NAME_get_text_by_NID == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&mFuncs.X509_free = idlOS::dlsym(mSslHandle, "X509_free");
    IDE_TEST_RAISE(mFuncs.X509_free == NULL, ERR_DLSYM_LIBSSL);

    /* BUG-46352 Output OpenSSL version */
    *(void**)&mFuncs.OpenSSL_version = idlOS::dlsym(mCryptoHandle, "OpenSSL_version");

    /* OpenSSL 3.x: initialization is automatic (OPENSSL_init_ssl/OPENSSL_init_crypto).
     * No explicit SSL_library_init(), OPENSSL_add_all_algorithms(),
     * or SSL_load_error_strings() calls are needed. */

    /* BUG-46352 Output OpenSSL version */
    if (mFuncs.OpenSSL_version != NULL)
    {
        ideLog::log(IDE_SERVER_0, "OpenSSL_version() : %s", mFuncs.OpenSSL_version(OPENSSL_VERSION));
    }

    mLibInitialized = ID_TRUE;

    return IDE_SUCCESS;

    IDE_EXCEPTION( ERR_DLSYM_LIBSSL )
    {
        IDE_SET(ideSetErrorCode(cmERR_ABORT_DLSYM, sOpensslSoName, idlOS::dlerror()));
    }
    IDE_EXCEPTION( ERR_DLOPEN_LIBSSL )
    {
        IDE_SET(ideSetErrorCode(cmERR_ABORT_DLOPEN, sOpensslSoName, idlOS::dlerror()));
    }
    IDE_EXCEPTION( ERR_DLOPEN_LIBCRYPTO )
    {
        IDE_SET(ideSetErrorCode(cmERR_ABORT_DLOPEN, sCryptoSoName, idlOS::dlerror()));
    }
    IDE_EXCEPTION_END;

    destroy();

    return IDE_FAILURE;
}

IDE_RC cmnOpenssl::destroy()
{
    if( mLibInitialized == ID_TRUE )
    {
        /* OpenSSL 3.x handles cleanup automatically via atexit().
         * No explicit cleanup calls are needed. */
        mLibInitialized = ID_FALSE;
    }
    else
    {
        /* No need to clean up */
    }

    if (mSslHandle != NULL)
    {
        (void)idlOS::dlclose(mSslHandle);
        mSslHandle = NULL;
    }
    else
    {
        /* mSslHandle is null */
    }

    if (mCryptoHandle != NULL)
    {
        (void)idlOS::dlclose(mCryptoHandle);
        mCryptoHandle = NULL;
    }
    else
    {
        /* mCryptoHandle is null */
    }

    return IDE_SUCCESS;
}

#endif /* CM_DISABLE_SSL */
