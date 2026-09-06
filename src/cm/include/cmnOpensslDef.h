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

#ifndef _O_CMN_OPENSSL_DEF_H_
#define _O_CMN_OPENSSL_DEF_H_ 1

#if !defined(CM_DISABLE_SSL)

#include <openssl/ssl.h>

typedef struct cmnOpensslFuncs
{
    SSL_CTX*            (*SSL_CTX_new)(const SSL_METHOD *aMethod);
    void                (*SSL_CTX_set_info_callback)(SSL_CTX *aCtx, void (*aCallback)(const SSL*, SInt, SInt));
    SInt                (*SSL_CTX_use_certificate_file)(SSL_CTX *aCtx, const SChar *aFile, SInt aType);
    void                (*SSL_CTX_set_default_passwd_cb)(SSL_CTX *aCtx, pem_password_cb *aCb);
    SInt                (*SSL_CTX_use_PrivateKey_file)(SSL_CTX *aCtx, const SChar *aFile, SInt aType);
    SInt                (*SSL_CTX_check_private_key)(const SSL_CTX *aCtx);

    const SSL_METHOD*   (*TLS_server_method)(void);
    const SSL_METHOD*   (*TLS_client_method)(void);

    SInt                (*SSL_CTX_set_cipher_list)(SSL_CTX *aSsl, const SChar *aStr);
    const SChar*        (*SSL_CIPHER_get_name)(const SSL_CIPHER *aCipher);
    SSL_CIPHER*         (*SSL_get_current_cipher)(const SSL *aSsl);

    void                (*SSL_CTX_set_verify_depth)(SSL_CTX *aSsl, SInt aDepth);
    SInt                (*SSL_CTX_load_verify_locations)(SSL_CTX     *aCtx,
                                                         const SChar *aCAfile,
                                                         const SChar *aCApath);
    SInt                (*SSL_CTX_set_default_verify_paths)(SSL_CTX *aCtx);
    SLong               (*SSL_CTX_ctrl)(SSL_CTX *aCtx, SInt aCmd, SLong aMode, void *aParg);
    void                (*SSL_CTX_set_client_CA_list)(SSL_CTX *aCtx, STACK_OF(X509_NAME) *aList);
    void                (*SSL_CTX_set_verify)(SSL_CTX *aCtx,
                                              SInt     aMode,
                                              SInt     (*aVerifyCallback)(SInt, X509_STORE_CTX *));
    void                (*SSL_CTX_free)(SSL_CTX *aCtx);

    X509*               (*SSL_get1_peer_certificate)(const SSL *aSsl);
    SLong               (*SSL_get_verify_result)(const SSL *aSsl);
    STACK_OF(X509_NAME)* (*SSL_load_client_CA_file)(const SChar *aFile);
    SInt                (*SSL_set_cipher_list)(SSL *aSsl, const SChar *aStr);

    void                (*SSL_set_quiet_shutdown)(SSL *aSsl, SInt aMode);
    SInt                (*SSL_shutdown)(SSL *aSsl);
    void                (*SSL_free)(SSL  *aSsl);

    SInt                (*SSL_get_error)(const SSL *aSsl, SInt aRet);

    ULong               (*ERR_get_error)(void);
    const SChar*        (*ERR_error_string)(ULong aError, SChar *aBuf);

    SInt                (*SSL_read)(SSL *aSsl, void *aBuf, SInt aNum);
    SInt                (*SSL_write)(SSL *aSsl, const void *aBuf, SInt aNum);

    SSL*                (*SSL_new)(SSL_CTX *aCtx);
    SInt                (*SSL_connect)(SSL *aSsl);
    SInt                (*SSL_set_fd)(SSL *aSsl, SInt fd);
    SInt                (*SSL_accept)(SSL *aSsl);

    const SChar*        (*SSL_state_string_long)(const SSL *aSsl);
    const SChar*        (*SSL_alert_type_string_long)(SInt aValue);
    const SChar*        (*SSL_alert_desc_string_long)(SInt aValue);

    X509_NAME*          (*X509_get_subject_name)(X509 *aA);
    SChar*              (*X509_NAME_oneline)(X509_NAME *aA, SChar *aBuf, SInt aSize);
    SInt                (*X509_NAME_get_text_by_NID)(X509_NAME *aName, SInt aNid, SChar *aBuf, SInt aLen);
    X509_NAME*          (*X509_get_issuer_name)(X509 *aA);
    void                (*X509_free)(const X509 *aCert);

    /* OpenSSL 3.x version query */
    const SChar*        (*OpenSSL_version)(SInt aType);
} cmnOpensslFuncs;

#define ALTIBASE_OPENSSL_LIB_NAME "ssl"
#define ALTIBASE_CRYPTO_LIB_NAME  "crypto"

#endif /* CM_DISABLE_SSL */

#endif  /* _O_CMN_OPENSSL_DEF_H_ */
