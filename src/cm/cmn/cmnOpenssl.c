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

#include <cmAllClient.h>
#include <cmnOpensslClient.h>

#if !defined(CM_DISABLE_SSL)

/* In case of client connections, it is allowable
 * if the client couldn't load the openssl library at cmiInitialize().
 * Therefore, the following two variables store a real error code and message
 * to let the client know the accurate reason for the failure of the library initialization
 * and are returned to the client at the appropriate time. */
#define SSL_LIB_ERROR_MSG_LEN (ACI_MAX_ERROR_MSG_LEN+256)  /* aciErrorMsg.h */
acp_uint32_t     gSslLibErrorCode = cmERR_IGNORE_NoError;
acp_char_t       gSslLibErrorMsg[SSL_LIB_ERROR_MSG_LEN] = {0,};

cmnOpenssl *gOpenssl = NULL;

ACI_RC cmnOpensslInitialize(cmnOpenssl **aOpenssl)
{
    acp_rc_t      sRC = ACP_RC_SUCCESS;
    cmnOpenssl   *sOpenssl = NULL;

    ACI_TEST(acpMemCalloc((void **)&sOpenssl, 1, sizeof(cmnOpenssl)) != ACP_RC_SUCCESS);

    sRC = acpDlOpen(&sOpenssl->mSslHandle, NULL, ALTIBASE_OPENSSL_LIB_NAME, ACP_TRUE);
    ACI_TEST_RAISE(sRC != ACP_RC_SUCCESS, ERR_DLOPEN_LIBSSL);

    sRC = acpDlOpen(&sOpenssl->mCryptoHandle, NULL, ALTIBASE_CRYPTO_LIB_NAME, ACP_TRUE);
    ACI_TEST_RAISE(sRC != ACP_RC_SUCCESS, ERR_DLOPEN_LIBCRYPTO);

    /* load functions */

    *(void**)&sOpenssl->mFuncs.SSL_CTX_new = acpDlSym(&sOpenssl->mSslHandle, "SSL_CTX_new");
    ACI_TEST_RAISE(sOpenssl->mFuncs.SSL_CTX_new == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&sOpenssl->mFuncs.TLS_server_method = acpDlSym(&sOpenssl->mSslHandle, "TLS_server_method");
    ACI_TEST_RAISE(sOpenssl->mFuncs.TLS_server_method == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&sOpenssl->mFuncs.TLS_client_method = acpDlSym(&sOpenssl->mSslHandle, "TLS_client_method");
    ACI_TEST_RAISE(sOpenssl->mFuncs.TLS_client_method == NULL, ERR_DLSYM_LIBSSL);

#if (DEBUG)  /* BUG-47037 OPENSSL_VERSION_NUMBER >= 0x00909000L */
    /* This function can be null depending on the library version
     * and is used only for debugging. */
    *(void**)&sOpenssl->mFuncs.SSL_CTX_set_info_callback = acpDlSym(&sOpenssl->mSslHandle, "SSL_CTX_set_info_callback");
#endif

    *(void**)&sOpenssl->mFuncs.SSL_CTX_use_certificate_file = acpDlSym(&sOpenssl->mSslHandle, "SSL_CTX_use_certificate_file");
    ACI_TEST_RAISE(sOpenssl->mFuncs.SSL_CTX_use_certificate_file == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&sOpenssl->mFuncs.SSL_CTX_set_default_passwd_cb = acpDlSym(&sOpenssl->mSslHandle, "SSL_CTX_set_default_passwd_cb");
    ACI_TEST_RAISE(sOpenssl->mFuncs.SSL_CTX_set_default_passwd_cb == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&sOpenssl->mFuncs.SSL_CTX_use_PrivateKey_file = acpDlSym(&sOpenssl->mSslHandle, "SSL_CTX_use_PrivateKey_file");
    ACI_TEST_RAISE(sOpenssl->mFuncs.SSL_CTX_use_PrivateKey_file == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&sOpenssl->mFuncs.SSL_CTX_check_private_key = acpDlSym(&sOpenssl->mSslHandle, "SSL_CTX_check_private_key");
    ACI_TEST_RAISE(sOpenssl->mFuncs.SSL_CTX_check_private_key == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&sOpenssl->mFuncs.SSL_CTX_set_cipher_list = acpDlSym(&sOpenssl->mSslHandle, "SSL_CTX_set_cipher_list");
    ACI_TEST_RAISE(sOpenssl->mFuncs.SSL_CTX_set_cipher_list == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&sOpenssl->mFuncs.SSL_get_current_cipher = acpDlSym(&sOpenssl->mSslHandle, "SSL_get_current_cipher");
    ACI_TEST_RAISE(sOpenssl->mFuncs.SSL_get_current_cipher == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&sOpenssl->mFuncs.SSL_CIPHER_get_name = acpDlSym(&sOpenssl->mSslHandle, "SSL_CIPHER_get_name");
    ACI_TEST_RAISE(sOpenssl->mFuncs.SSL_CIPHER_get_name == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&sOpenssl->mFuncs.SSL_CTX_set_verify_depth = acpDlSym(&sOpenssl->mSslHandle, "SSL_CTX_set_verify_depth");
    ACI_TEST_RAISE(sOpenssl->mFuncs.SSL_CTX_set_verify_depth == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&sOpenssl->mFuncs.SSL_CTX_load_verify_locations = acpDlSym(&sOpenssl->mSslHandle, "SSL_CTX_load_verify_locations");
    ACI_TEST_RAISE(sOpenssl->mFuncs.SSL_CTX_load_verify_locations == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&sOpenssl->mFuncs.SSL_CTX_set_default_verify_paths = acpDlSym(&sOpenssl->mSslHandle, "SSL_CTX_set_default_verify_paths");
    ACI_TEST_RAISE(sOpenssl->mFuncs.SSL_CTX_set_default_verify_paths == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&sOpenssl->mFuncs.SSL_CTX_ctrl = acpDlSym(&sOpenssl->mSslHandle, "SSL_CTX_ctrl");
    ACI_TEST_RAISE(sOpenssl->mFuncs.SSL_CTX_ctrl == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&sOpenssl->mFuncs.SSL_CTX_set_client_CA_list = acpDlSym(&sOpenssl->mSslHandle, "SSL_CTX_set_client_CA_list");
    ACI_TEST_RAISE(sOpenssl->mFuncs.SSL_CTX_set_client_CA_list == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&sOpenssl->mFuncs.SSL_CTX_set_verify = acpDlSym(&sOpenssl->mSslHandle, "SSL_CTX_set_verify");
    ACI_TEST_RAISE(sOpenssl->mFuncs.SSL_CTX_set_verify == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&sOpenssl->mFuncs.SSL_CTX_free = acpDlSym(&sOpenssl->mSslHandle, "SSL_CTX_free");
    ACI_TEST_RAISE(sOpenssl->mFuncs.SSL_CTX_free == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&sOpenssl->mFuncs.SSL_set_quiet_shutdown = acpDlSym(&sOpenssl->mSslHandle, "SSL_set_quiet_shutdown");
    ACI_TEST_RAISE(sOpenssl->mFuncs.SSL_set_quiet_shutdown == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&sOpenssl->mFuncs.SSL_get1_peer_certificate = acpDlSym(&sOpenssl->mSslHandle, "SSL_get1_peer_certificate");
    ACI_TEST_RAISE(sOpenssl->mFuncs.SSL_get1_peer_certificate == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&sOpenssl->mFuncs.SSL_get_verify_result = acpDlSym(&sOpenssl->mSslHandle, "SSL_get_verify_result");
    ACI_TEST_RAISE(sOpenssl->mFuncs.SSL_get_verify_result == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&sOpenssl->mFuncs.SSL_load_client_CA_file = acpDlSym(&sOpenssl->mSslHandle, "SSL_load_client_CA_file");
    ACI_TEST_RAISE(sOpenssl->mFuncs.SSL_load_client_CA_file == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&sOpenssl->mFuncs.SSL_set_cipher_list = acpDlSym(&sOpenssl->mSslHandle, "SSL_set_cipher_list");
    ACI_TEST_RAISE(sOpenssl->mFuncs.SSL_set_cipher_list == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&sOpenssl->mFuncs.SSL_shutdown = acpDlSym(&sOpenssl->mSslHandle, "SSL_shutdown");
    ACI_TEST_RAISE(sOpenssl->mFuncs.SSL_shutdown == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&sOpenssl->mFuncs.SSL_free = acpDlSym(&sOpenssl->mSslHandle, "SSL_free");
    ACI_TEST_RAISE(sOpenssl->mFuncs.SSL_free == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&sOpenssl->mFuncs.SSL_get_error = acpDlSym(&sOpenssl->mSslHandle, "SSL_get_error");
    ACI_TEST_RAISE(sOpenssl->mFuncs.SSL_get_error == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&sOpenssl->mFuncs.ERR_error_string = acpDlSym(&sOpenssl->mSslHandle, "ERR_error_string");
    ACI_TEST_RAISE(sOpenssl->mFuncs.ERR_error_string == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&sOpenssl->mFuncs.ERR_get_error = acpDlSym(&sOpenssl->mSslHandle, "ERR_get_error");
    ACI_TEST_RAISE(sOpenssl->mFuncs.ERR_get_error == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&sOpenssl->mFuncs.SSL_read = acpDlSym(&sOpenssl->mSslHandle, "SSL_read");
    ACI_TEST_RAISE(sOpenssl->mFuncs.SSL_read == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&sOpenssl->mFuncs.SSL_write = acpDlSym(&sOpenssl->mSslHandle, "SSL_write");
    ACI_TEST_RAISE(sOpenssl->mFuncs.SSL_write == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&sOpenssl->mFuncs.SSL_new = acpDlSym(&sOpenssl->mSslHandle, "SSL_new");
    ACI_TEST_RAISE(sOpenssl->mFuncs.SSL_new == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&sOpenssl->mFuncs.SSL_connect = acpDlSym(&sOpenssl->mSslHandle, "SSL_connect");
    ACI_TEST_RAISE(sOpenssl->mFuncs.SSL_connect == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&sOpenssl->mFuncs.SSL_set_fd = acpDlSym(&sOpenssl->mSslHandle, "SSL_set_fd");
    ACI_TEST_RAISE(sOpenssl->mFuncs.SSL_set_fd == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&sOpenssl->mFuncs.SSL_accept = acpDlSym(&sOpenssl->mSslHandle, "SSL_accept");
    ACI_TEST_RAISE(sOpenssl->mFuncs.SSL_accept == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&sOpenssl->mFuncs.SSL_state_string_long = acpDlSym(&sOpenssl->mSslHandle, "SSL_state_string_long");
    ACI_TEST_RAISE(sOpenssl->mFuncs.SSL_state_string_long == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&sOpenssl->mFuncs.SSL_alert_type_string_long = acpDlSym(&sOpenssl->mSslHandle, "SSL_alert_type_string_long");
    ACI_TEST_RAISE(sOpenssl->mFuncs.SSL_alert_type_string_long == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&sOpenssl->mFuncs.SSL_alert_desc_string_long = acpDlSym(&sOpenssl->mSslHandle, "SSL_alert_desc_string_long");
    ACI_TEST_RAISE(sOpenssl->mFuncs.SSL_alert_desc_string_long == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&sOpenssl->mFuncs.X509_NAME_oneline = acpDlSym(&sOpenssl->mSslHandle, "X509_NAME_oneline");
    ACI_TEST_RAISE(sOpenssl->mFuncs.X509_NAME_oneline == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&sOpenssl->mFuncs.X509_get_subject_name = acpDlSym(&sOpenssl->mSslHandle, "X509_get_subject_name");
    ACI_TEST_RAISE(sOpenssl->mFuncs.X509_get_subject_name == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&sOpenssl->mFuncs.X509_get_issuer_name = acpDlSym(&sOpenssl->mSslHandle, "X509_get_issuer_name");
    ACI_TEST_RAISE(sOpenssl->mFuncs.X509_get_issuer_name == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&sOpenssl->mFuncs.X509_NAME_get_text_by_NID = acpDlSym(&sOpenssl->mSslHandle, "X509_NAME_get_text_by_NID");
    ACI_TEST_RAISE(sOpenssl->mFuncs.X509_NAME_get_text_by_NID == NULL, ERR_DLSYM_LIBSSL);

    *(void**)&sOpenssl->mFuncs.X509_free = acpDlSym(&sOpenssl->mSslHandle, "X509_free");
    ACI_TEST_RAISE(sOpenssl->mFuncs.X509_free == NULL, ERR_DLSYM_LIBSSL);

    /* OpenSSL 3.x version query */
    *(void**)&sOpenssl->mFuncs.OpenSSL_version = acpDlSym(&sOpenssl->mCryptoHandle, "OpenSSL_version");

    /* OpenSSL 3.x: initialization is automatic (OPENSSL_init_ssl/OPENSSL_init_crypto).
     * No explicit SSL_library_init(), OPENSSL_add_all_algorithms(),
     * or SSL_load_error_strings() calls are needed. */

    sOpenssl->mLibInitialized = ACP_TRUE;

    *aOpenssl = sOpenssl;

    return ACI_SUCCESS;

    ACI_EXCEPTION( ERR_DLSYM_LIBSSL )
    {
        ACI_SET(aciSetErrorCode(cmERR_ABORT_DLSYM, ALTIBASE_OPENSSL_LIB_NAME, acpDlError(&sOpenssl->mSslHandle)));
    }
    ACI_EXCEPTION( ERR_DLOPEN_LIBSSL)
    {
        ACI_SET(aciSetErrorCode(cmERR_ABORT_DLOPEN, ALTIBASE_OPENSSL_LIB_NAME, acpDlError(&sOpenssl->mSslHandle)));
    }
    ACI_EXCEPTION( ERR_DLOPEN_LIBCRYPTO )
    {
        ACI_SET(aciSetErrorCode(cmERR_ABORT_DLOPEN, ALTIBASE_CRYPTO_LIB_NAME, acpDlError(&sOpenssl->mCryptoHandle)));
    }
    ACI_EXCEPTION_END;

    gSslLibErrorCode = aciGetErrorCode();
    acpSnprintf(gSslLibErrorMsg, SSL_LIB_ERROR_MSG_LEN, "%s", aciGetErrorMsg(gSslLibErrorCode));

    if (sOpenssl != NULL) /* BUG-45235 */
    {
        (void)cmnOpensslDestroy(&sOpenssl);
    }
    else
    {
        /* failed to allocate */
    }

    return ACI_FAILURE;
}

ACI_RC cmnOpensslDestroy(cmnOpenssl **aOpenssl)
{
    cmnOpenssl   *sOpenssl = *aOpenssl;

    if (sOpenssl != NULL)
    {
        if (sOpenssl->mLibInitialized == ACP_TRUE)
        {
            /* OpenSSL 3.x handles cleanup automatically via atexit().
             * No explicit cleanup calls are needed. */
            sOpenssl->mLibInitialized = ACP_FALSE;
        }
        else
        {
            /* not initialized */
        }

        if (sOpenssl->mSslHandle.mHandle != NULL)
        {
            (void)acpDlClose(&sOpenssl->mSslHandle);
            sOpenssl->mSslHandle.mHandle = NULL;
        }
        else
        {
            /* already closed */
        }

        if (sOpenssl->mCryptoHandle.mHandle != NULL)
        {
            (void)acpDlClose(&sOpenssl->mCryptoHandle);
            sOpenssl->mCryptoHandle.mHandle = NULL;
        }
        else
        {
            /* already closed */
        }

        acpMemFree(*aOpenssl);
        *aOpenssl = NULL;
    }
    else
    {
        /* already freed */
    }

    return ACI_SUCCESS;
}

const acp_char_t *cmnOpensslErrorMessage(cmnOpenssl *aOpenssl)
{
    ACI_TEST_RAISE(gOpenssl == NULL, NoSslLibrary);

    return aOpenssl->mFuncs.ERR_error_string(aOpenssl->mFuncs.ERR_get_error(), NULL);

    ACI_EXCEPTION(NoSslLibrary)
    {
        aciSetErrorCodeAndMsg(gSslLibErrorCode, gSslLibErrorMsg);
    }
    ACI_EXCEPTION_END;

    return (acp_char_t *)NULL;
}

#endif /* CM_DISABLE_SSL */
