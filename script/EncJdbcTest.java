/*
 * Copyright (c) 2026 DBVM (dbvm.com). All rights reserved.
 *
 * Client-side (JDBC) test for encrypted columns.
 */
import java.sql.*;

public class EncJdbcTest
{
    static int sFails = 0;

    static void check(boolean cond, String msg)
    {
        System.out.println((cond ? "[PASS] " : "[FAIL] ") + msg);
        if (!cond)
        {
            sFails++;
        }
    }

    public static void main(String[] args) throws Exception
    {
        Class.forName("Altibase.jdbc.driver.AltibaseDriver");
        String port = System.getenv().getOrDefault("ENC_TEST_PORT", "17730");
        String url = "jdbc:Altibase://localhost:" + port + "/mydb";
        try (Connection c = DriverManager.getConnection(url, "sys", "MANAGER"))
        {
            System.out.println("[PASS] jdbc connect");
            c.setAutoCommit(false);

            /* 0. reset the test table to a known state (clear leftovers from
             * other client tests that use the same t_cli table) and seed
             * the rows that the following checks rely on. */
            Statement st = c.createStatement();
            st.executeUpdate("DELETE FROM t_cli WHERE id >= 100");
            c.commit();
            st.executeUpdate("INSERT INTO t_cli VALUES (100, 'jdbc alpha secret', 'N')");
            st.executeUpdate("INSERT INTO t_cli VALUES (101, 'jdbc beta hidden', 'Y')");
            c.commit();

            /* 1. plain SELECT with metadata: the driver must report the
             * original CHAR/VARCHAR types and sizes for the encrypted
             * columns, and return the decrypted values. */
            ResultSet rs = st.executeQuery(
                "SELECT id, v_name, flag FROM t_cli WHERE id >= 100 ORDER BY id");
            ResultSetMetaData md = rs.getMetaData();
            int tt2 = md.getColumnType(2);
            int tt3 = md.getColumnType(3);
            String tn2 = md.getColumnTypeName(2);
            String tn3 = md.getColumnTypeName(3);
            int disp2 = md.getColumnDisplaySize(2);
            System.out.println("      v_name typeName=" + tn2 + " type=" + tt2
                               + " displaySize=" + disp2);
            System.out.println("      flag   typeName=" + tn3 + " type=" + tt3);
            while (rs.next())
            {
                System.out.println("      id=" + rs.getInt(1) + " v='" + rs.getString(2)
                                   + "' flag='" + rs.getString(3) + "'");
            }
            rs.close();

            /* 2. parameterized WHERE over an encrypted column: a bound
             * value must locate the plaintext row. */
            PreparedStatement ps = c.prepareStatement(
                "SELECT v_name FROM t_cli WHERE v_name = ?");
            ps.setString(1, "jdbc beta hidden");
            rs = ps.executeQuery();
            String got = "";
            while (rs.next())
            {
                got = rs.getString(1);
            }
            System.out.println("      where='jdbc beta hidden' -> '" + got + "'");
            check("jdbc beta hidden".equals(got), "JDBC parameterized WHERE on encrypted col");
            ps.close();

            /* 3. parameterized UPDATE of encrypted columns, then verify the
             * new values are readable and the change is committed. */
            PreparedStatement pu = c.prepareStatement(
                "UPDATE t_cli SET v_name = ?, flag = ? WHERE id = ?");
            pu.setString(1, "jdbc updated value");
            pu.setString(2, "Z");
            pu.setInt(3, 100);
            int n = pu.executeUpdate();
            check(n == 1, "JDBC UPDATE encrypted cols");
            c.commit();
            pu.close();

            rs = st.executeQuery("SELECT v_name, flag FROM t_cli WHERE id = 100");
            rs.next();
            System.out.println("      after update v='" + rs.getString(1) + "' flag='"
                               + rs.getString(2) + "'");
            check("jdbc updated value".equals(rs.getString(1)) && "Z".equals(rs.getString(2)),
                  "JDBC updated encrypted value visible");
            rs.close();

            /* 4. LIKE with a wildcard over an encrypted column. */
            rs = st.executeQuery(
                "SELECT v_name FROM t_cli WHERE id = 101 AND v_name LIKE 'jdbc%'");
            check(rs.next() && "jdbc beta hidden".equals(rs.getString(1)),
                  "JDBC LIKE on encrypted col");
            rs.close();

            st.close();
            c.commit();
        }

        System.out.println(sFails == 0 ? "JDBC_ENC_TEST_ALL_PASS" : "JDBC_ENC_TEST_FAIL");
        if (sFails != 0)
        {
            System.exit(1);
        }
    }
}