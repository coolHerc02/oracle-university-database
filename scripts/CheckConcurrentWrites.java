import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.sql.*;

public class CheckConcurrentWrites {
    private static int passed = 0;
    private static void check(boolean ok, String text) {
        if (!ok) throw new IllegalStateException("FAIL: " + text);
        passed++;
        System.out.println("PASS " + passed + ": " + text);
    }
    private static int grade(Connection c) throws SQLException {
        try (PreparedStatement s = c.prepareStatement(
                "select grade_value from grades where faculty_number='00010001' and discipline_id=1");
             ResultSet r = s.executeQuery()) {
            if (!r.next()) throw new SQLException("Missing seeded grade");
            return r.getInt(1);
        }
    }
    private static void update(Connection c, int value) throws SQLException {
        try (CallableStatement s = c.prepareCall("begin grade_upd('00010001',1,?,date '2026-06-15'); end;")) {
            s.setInt(1, value);
            s.execute();
        }
    }
    private static int assignments(Connection c) throws SQLException {
        try (Statement s=c.createStatement(); ResultSet r=s.executeQuery(
                "select count(*) from discipline_teachers where discipline_id=1")) {
            r.next(); return r.getInt(1);
        }
    }
    private static void assign(Connection c,int teacher) throws SQLException {
        try(CallableStatement s=c.prepareCall("begin discipline_teacher_ins(1,?); end;")) {
            s.setInt(1,teacher);s.execute();
        }
    }
    public static void main(String[] args) throws Exception {
        // Password is supplied on standard input, never as a command-line argument.
        String password = new BufferedReader(new InputStreamReader(System.in, "UTF-8")).readLine();
        Class.forName("oracle.jdbc.OracleDriver");
        try (Connection first = DriverManager.getConnection("jdbc:oracle:thin:@//localhost:1521/XE", "UNIVERSITY_PROJECT", password);
             Connection second = DriverManager.getConnection("jdbc:oracle:thin:@//localhost:1521/XE", "UNIVERSITY_PROJECT", password)) {
            password = null;
            first.setAutoCommit(false);
            second.setAutoCommit(false);
            try {
                int baseline = grade(first);
                check(baseline == 6, "Seed grade before concurrency test is six");
                update(first, 5);
                check(grade(first) == 5 && grade(second) == 6, "Other session sees committed baseline while writer holds locks");
                int error = 0;
                try { update(second, 4); } catch (SQLException expected) { error = expected.getErrorCode(); }
                check(error == 54, "Competing writer receives ORA-00054 NOWAIT refusal");
                first.rollback();
                update(second, 4);
                check(grade(second) == 4 && grade(first) == 6, "Writer succeeds after first ROLLBACK, with transaction isolation");
                second.rollback();
                check(grade(first) == 6 && grade(second) == 6, "Both ROLLBACK operations restore original grade");
                check(assignments(first)==2 && assignments(second)==2,
                        "Shared discipline has two committed teachers");
                assign(first,6);
                check(assignments(first)==3 && assignments(second)==2,
                        "Uncommitted teaching assignment is isolated from other session");
                error=0;
                try {assign(second,5);} catch(SQLException expected){error=expected.getErrorCode();}
                check(error==54,"Competing assignment writer receives NOWAIT refusal");
                first.rollback();
                assign(second,5);
                check(assignments(second)==3 && assignments(first)==2,
                        "Assignment writer succeeds after lock release");
                second.rollback();
                check(assignments(first)==2 && assignments(second)==2,
                        "Both rollbacks preserve the two seeded teachers");
                System.out.println("CONCURRENCY_VALIDATION_PASSED: " + passed + " checks");
            } finally {
                first.rollback();
                second.rollback();
            }
        }
    }
}
