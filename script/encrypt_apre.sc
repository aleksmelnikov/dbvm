/******************************************************************
 * Copyright (c) 2026 DBVM (dbvm.com). All rights reserved.
 *
 * Encrypted columns test via APRE (embedded SQL / C++).
 *
 * Verifies that APRE-precompiled C++ code can work with encrypted
 * CHAR/VARCHAR columns transparently: INSERT / UPDATE / SELECT into
 * encrypted columns and WHERE over them.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

EXEC SQL BEGIN DECLARE SECTION;
char        usr[10];
char        pwd[10];
char        conn_opt[256];
short       s_id;
char        s_v[40];
char        s_f[2];
short       i_id;
char        i_v[40];
char        i_f[2];
EXEC SQL END DECLARE SECTION;

static int s_fails = 0;

static void check(int cond, const char* msg)
{
    printf("%s %s\n", cond ? "[PASS]" : "[FAIL]", msg);
    if (!cond)
    {
        s_fails++;
    }
}

int main()
{
    const char* env_port = getenv("ENC_TEST_PORT");
    const char* port = env_port != NULL ? env_port : "17730";

    strcpy(usr, "SYS");
    strcpy(pwd, "MANAGER");
    sprintf(conn_opt, "Server=127.0.0.1;Port=%s", port);

    EXEC SQL CONNECT :usr IDENTIFIED BY :pwd USING :conn_opt;
    if (sqlca.sqlcode != 0)
    {
        printf("[FAIL] APRE connect error: [%ld] %s\n",
               (long)sqlca.sqlcode, sqlca.sqlerrm.sqlerrmc);
        return 1;
    }
    printf("[PASS] APRE connect ok\n");

    /* reset and seed */
    EXEC SQL DELETE FROM t_cli;
    EXEC SQL COMMIT WORK;
    i_id = 1; strcpy(i_v, "alpha secret"); strcpy(i_f, "N");
    EXEC SQL INSERT INTO t_cli VALUES (:i_id, :i_v, :i_f);
    i_id = 2; strcpy(i_v, "beta hidden value"); strcpy(i_f, "Y");
    EXEC SQL INSERT INTO t_cli VALUES (:i_id, :i_v, :i_f);
    check(sqlca.sqlcode == 0, "APRE INSERT into encrypted columns");
    EXEC SQL COMMIT WORK;

    /* SELECT into host variables */
    s_id = 2;
    EXEC SQL SELECT v_name, flag INTO :s_v, :s_f FROM t_cli WHERE id = :s_id;
    printf("      row id=%d v='%s' f='%s'\n", s_id, s_v, s_f);
    check(sqlca.sqlcode == 0 && strcmp(s_v, "beta hidden value") == 0 &&
          s_f[0] == 'Y',
          "APRE SELECT decrypts value into host variable");

    /* parameterized WHERE over encrypted column */
    strcpy(s_v, "alpha secret");
    EXEC SQL SELECT id INTO :s_id FROM t_cli WHERE v_name = :s_v;
    check(sqlca.sqlcode == 0 && s_id == 1,
          "APRE parameterized WHERE locates plaintext row");

    /* UPDATE encrypted column */
    strcpy(i_v, "updated value"); i_id = 2;
    EXEC SQL UPDATE t_cli SET v_name = :i_v WHERE id = :i_id;
    EXEC SQL COMMIT WORK;
    s_id = 2;
    EXEC SQL SELECT v_name INTO :s_v FROM t_cli WHERE id = :s_id;
    check(sqlca.sqlcode == 0 && strcmp(s_v, "updated value") == 0,
          "APRE UPDATE on encrypted column");

    EXEC SQL DISCONNECT;

    printf(s_fails == 0 ? "APR_ENC_TEST_ALL_PASS\n" : "APR_ENC_TEST_FAIL\n");
    return s_fails == 0 ? 0 : 1;
}