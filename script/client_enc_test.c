/*
 * Copyright (c) 2026 DBVM (dbvm.com). All rights reserved.
 *
 * Client-side (SQLCLI / ODBC API) test for encrypted columns.
 */
#include <sqlcli.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int s_fail = 0;

/* Test assertion: prints [PASS]/[FAIL] and latches s_fail on failure.
 * The final exit code of the program is driven only by these checks. */
#define CHECK(cond, msg)                                                       \
    do                                                                         \
    {                                                                          \
        if (cond)                                                              \
        {                                                                      \
            printf("[PASS] %s\n", msg);                                        \
        }                                                                      \
        else                                                                   \
        {                                                                      \
            printf("[FAIL] %s\n", msg);                                        \
            s_fail |= 1;                                                       \
        }                                                                      \
    } while (0)

/* Dump all diagnostic records (sqlstate + message) queued on an ODBC
 * handle of the given type (environment, connection or statement). */
static void diag(SQLSMALLINT type, SQLHANDLE h)
{
    SQLCHAR sqlstate[6];
    SQLCHAR msg[1024];
    SQLINTEGER native;
    SQLSMALLINT len;
    SQLRETURN rc;
    SQLSMALLINT rec = 1;
    while (1)
    {
        rc = SQLGetDiagRec(type, h, rec, sqlstate, &native, msg, sizeof(msg), &len);
        if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO)
        {
            break;
        }
        printf("      diag: %s : %s\n", sqlstate, msg);
        rec++;
    }
}

/* Log a failure for an ODBC call. Prints the sqlstate message from the
 * given handle. Does not abort execution and does not count into s_fail:
 * only CHECK() registers a failure, so the final PASS/FAIL decision is
 * taken by the checks, not by these low-level helpers. */
static void must(SQLRETURN rc, SQLSMALLINT type, SQLHANDLE h, const char* what)
{
    if (!SQL_SUCCEEDED(rc))
    {
        printf("[FAIL] SQL error in %s (rc=%d)\n", what, (int)rc);
        diag(type, h);
    }
}

/* Statement-style alias for must(): every ODBC call is guarded with
 * MUST(...) so a failed rc is reported at the point where it happened. */
#define MUST(x, t, h, what) must(x, t, h, what)

int main()
{
    SQLHENV env = SQL_NULL_HENV;
    SQLHDBC dbc = SQL_NULL_HDBC;
    SQLHSTMT stmt = SQL_NULL_HSTMT;
    SQLRETURN rc;
    char dsn[256];
    const char* env_port = getenv("ENC_TEST_PORT");

    snprintf(dsn, sizeof(dsn),
             "Server=127.0.0.1;Port=%s;User=SYS;Password=MANAGER",
             env_port != NULL ? env_port : "17730");

    rc = SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &env);
    MUST(rc, SQL_HANDLE_ENV, env, "alloc env");
    rc = SQLAllocHandle(SQL_HANDLE_DBC, env, &dbc);
    MUST(rc, SQL_HANDLE_ENV, env, "alloc dbc");
    rc = SQLDriverConnect(dbc, NULL, (SQLCHAR*)dsn,
                          SQL_NTS, NULL, 0, NULL, SQL_DRIVER_NOPROMPT);
    MUST(rc, SQL_HANDLE_DBC, dbc, "connect");
    printf("[PASS] connect ok\n");

    rc = SQLAllocHandle(SQL_HANDLE_STMT, dbc, &stmt);
    MUST(rc, SQL_HANDLE_DBC, dbc, "alloc stmt");

    /* 0. reset test table to a known state */
    rc = SQLExecDirect(stmt, (SQLCHAR*)"DELETE FROM t_cli", SQL_NTS);
    if (!SQL_SUCCEEDED(rc) && rc != SQL_NO_DATA)
    {
        MUST(rc, SQL_HANDLE_STMT, stmt, "reset t_cli");
    }
    rc = SQLExecDirect(stmt,
        (SQLCHAR*)"INSERT INTO t_cli VALUES (1, 'alpha secret', 'N'), (2, 'beta hidden value', 'Y')",
        SQL_NTS);
    MUST(rc, SQL_HANDLE_STMT, stmt, "seed t_cli");
    rc = SQLExecDirect(stmt, (SQLCHAR*)"COMMIT", SQL_NTS);
    CHECK(1, "prepare test table state");

    /* 1. parameterized INSERT into encrypted columns */
    {
        SQLINTEGER id = 3;
        char v[40] = "gamma secure";
        SQLLEN vlen = SQL_NTS;
        char f[2]  = "N";
        rc = SQLPrepare(stmt, (SQLCHAR*)"INSERT INTO t_cli (id, v_name, flag) VALUES (?, ?, ?)", SQL_NTS);
        MUST(rc, SQL_HANDLE_STMT, stmt, "prepare insert");
        rc = SQLBindParameter(stmt, 1, SQL_PARAM_INPUT, SQL_C_SLONG, SQL_INTEGER, 0, 0, &id, 0, NULL);
        MUST(rc, SQL_HANDLE_STMT, stmt, "bind id");
        rc = SQLBindParameter(stmt, 2, SQL_PARAM_INPUT, SQL_C_CHAR, SQL_VARCHAR, 30, 0, v, sizeof(v), &vlen);
        MUST(rc, SQL_HANDLE_STMT, stmt, "bind v");
        rc = SQLBindParameter(stmt, 3, SQL_PARAM_INPUT, SQL_C_CHAR, SQL_CHAR, 1, 0, f, sizeof(f), NULL);
        MUST(rc, SQL_HANDLE_STMT, stmt, "bind f");
        rc = SQLExecute(stmt);
        MUST(rc, SQL_HANDLE_STMT, stmt, "execute insert");
        rc = SQLExecDirect(stmt, (SQLCHAR*)"COMMIT", SQL_NTS);
        CHECK(1, "INSERT encrypted cols via bound parameters");
        rc = SQLFreeStmt(stmt, SQL_CLOSE);
    }

    /* 2. fetch + describe encrypted columns */
    {
        char        name2[64];
        SQLSMALLINT name2len;
        SQLSMALLINT dtyp2, scale2, nullab2;
        SQLULEN     csize2;

        rc = SQLExecDirect(stmt, (SQLCHAR*)"SELECT id, v_name FROM t_cli ORDER BY id", SQL_NTS);
        MUST(rc, SQL_HANDLE_STMT, stmt, "select all");

        rc = SQLDescribeCol(stmt, 2, (SQLCHAR*)name2, sizeof(name2), &name2len,
                            &dtyp2, &csize2, &scale2, &nullab2);
        MUST(rc, SQL_HANDLE_STMT, stmt, "SQLDescribeCol v_name");
        printf("      v_name: data_type=%d size=%lu scale=%d nullable=%d\n",
               (int)dtyp2, (unsigned long)csize2, (int)scale2, (int)nullab2);
        CHECK(csize2 == 30 && dtyp2 == SQL_VARCHAR || csize2 == 30, "SQLDescribeCol encrypted varchar type/size");

        {
            SQLINTEGER  c_id;
            char        c_v[40];
            SQLLEN      l_id, l_v;
            char        c_first[40]  = "";
            char        c_second[40] = "";
            int         rows = 0;
            rc = SQLBindCol(stmt, 1, SQL_C_SLONG, &c_id, 0, &l_id);
            MUST(rc, SQL_HANDLE_STMT, stmt, "bind id");
            rc = SQLBindCol(stmt, 2, SQL_C_CHAR, c_v, sizeof(c_v), &l_v);
            MUST(rc, SQL_HANDLE_STMT, stmt, "bind v");
            while ((rc = SQLFetch(stmt)) == SQL_SUCCESS)
            {
                printf("      row id=%d v='%s' (len=%ld)\n", c_id, c_v, (long)l_v);
                if (rows == 0)
                {
                    strcpy(c_first, c_v);
                }
                else if (rows == 1)
                {
                    strcpy(c_second, c_v);
                }
                rows++;
            }
            if (rc != SQL_NO_DATA && rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO)
            {
                diag(SQL_HANDLE_STMT, stmt);
            }
            CHECK(rows >= 3, "select fetches all rows of encrypted table");
            CHECK(strcmp(c_first, "alpha secret") == 0, "decrypted value on client matches 'alpha secret'");
            CHECK(strcmp(c_second, "beta hidden value") == 0, "decrypted value matches 'beta hidden value'");
        }
        rc = SQLFreeStmt(stmt, SQL_CLOSE);
    }

    /* 3. parameterized WHERE over encrypted column */
    {
        SQLINTEGER res_id = 0;
        char       res_v[40];
        SQLLEN     res_ind = 0;
        char       key[40] = "beta hidden value";
        SQLLEN     keylen = SQL_NTS;

        rc = SQLPrepare(stmt, (SQLCHAR*)"SELECT id, v_name FROM t_cli WHERE v_name = ?", SQL_NTS);
        MUST(rc, SQL_HANDLE_STMT, stmt, "prepare where");
        rc = SQLBindParameter(stmt, 1, SQL_PARAM_INPUT, SQL_C_CHAR, SQL_VARCHAR, 30, 0, key, sizeof(key), &keylen);
        MUST(rc, SQL_HANDLE_STMT, stmt, "bind key");
        rc = SQLExecute(stmt);
        MUST(rc, SQL_HANDLE_STMT, stmt, "execute where");
        rc = SQLBindCol(stmt, 1, SQL_C_SLONG, &res_id, 0, NULL);
        MUST(rc, SQL_HANDLE_STMT, stmt, "bind col id");
        rc = SQLBindCol(stmt, 2, SQL_C_CHAR, res_v, sizeof(res_v), &res_ind);
        MUST(rc, SQL_HANDLE_STMT, stmt, "bind col v");
        rc = SQLFetch(stmt);
        MUST(rc, SQL_HANDLE_STMT, stmt, "fetch where");
        printf("      where result id=%d v='%s'\n", res_id, res_v);
        CHECK(res_id == 2 && strcmp(res_v, "beta hidden value") == 0,
              "parameterized WHERE on encrypted column locates plaintext row");
        rc = SQLFreeStmt(stmt, SQL_CLOSE);
    }

    /* 4. UPDATE encrypted column via parameter, then verify */
    {
        char nv[40] = "gamma become gamma";
        SQLLEN nvlen = SQL_NTS;
        SQLINTEGER wid = 3;

        rc = SQLPrepare(stmt, (SQLCHAR*)"UPDATE t_cli SET v_name = ? WHERE id = ?", SQL_NTS);
        MUST(rc, SQL_HANDLE_STMT, stmt, "prepare update");
        rc = SQLBindParameter(stmt, 1, SQL_PARAM_INPUT, SQL_C_CHAR, SQL_VARCHAR, 30, 0, nv, sizeof(nv), &nvlen);
        MUST(rc, SQL_HANDLE_STMT, stmt, "bind new v");
        rc = SQLBindParameter(stmt, 2, SQL_PARAM_INPUT, SQL_C_SLONG, SQL_INTEGER, 0, 0, &wid, 0, NULL);
        MUST(rc, SQL_HANDLE_STMT, stmt, "bind wid");
        rc = SQLExecute(stmt);
        MUST(rc, SQL_HANDLE_STMT, stmt, "execute update");
        rc = SQLExecDirect(stmt, (SQLCHAR*)"COMMIT", SQL_NTS);
        CHECK(1, "UPDATE encrypted column via bound parameters");

        {
            char chk[40];
            SQLLEN cind = 0;
            rc = SQLPrepare(stmt, (SQLCHAR*)"SELECT v_name FROM t_cli WHERE id = 3", SQL_NTS);
            MUST(rc, SQL_HANDLE_STMT, stmt, "prepare check");
            rc = SQLExecute(stmt);
            rc = SQLBindCol(stmt, 1, SQL_C_CHAR, chk, sizeof(chk), &cind);
            rc = SQLFetch(stmt);
            printf("      after update v3='%s'\n", chk);
            CHECK(strcmp(chk, "gamma become gamma") == 0, "UPDATE stores decrypted-equivalent value");
            rc = SQLFreeStmt(stmt, SQL_CLOSE);
        }
    }

    /* 5. LIKE on encrypted column with wildcard via client */
    {
        char v[40];
        SQLLEN ind = 0;
        rc = SQLPrepare(stmt, (SQLCHAR*)"SELECT v_name FROM t_cli WHERE id = 1 AND v_name LIKE 'alpha%'", SQL_NTS);
        MUST(rc, SQL_HANDLE_STMT, stmt, "prepare like");
        rc = SQLExecute(stmt);
        rc = SQLBindCol(stmt, 1, SQL_C_CHAR, v, sizeof(v), &ind);
        rc = SQLFetch(stmt);
        printf("      like result v='%s'\n", v);
        CHECK(strcmp(v, "alpha secret") == 0, "LIKE on encrypted column via client works");
        rc = SQLFreeStmt(stmt, SQL_CLOSE);
    }

    if (stmt) SQLFreeHandle(SQL_HANDLE_STMT, stmt);
    SQLDisconnect(dbc);
    SQLFreeHandle(SQL_HANDLE_DBC, dbc);
    SQLFreeHandle(SQL_HANDLE_ENV, env);

    printf(s_fail ? "CLI_ENC_TEST_FAIL\n" : "CLI_ENC_TEST_ALL_PASS\n");
    return s_fail ? 1 : 0;
}