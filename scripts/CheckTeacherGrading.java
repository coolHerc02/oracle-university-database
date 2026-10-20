import java.io.*;
import java.sql.*;
import java.util.*;

/** Authenticate as real teacher users; never accepts a password on the command line. */
public class CheckTeacherGrading {
    static int passed=0;
    static void check(boolean ok,String message) {
        if(!ok)throw new IllegalStateException("FAIL: "+message);
        System.out.println("PASS "+(++passed)+": "+message);
    }
    static Connection connect(String user,String password)throws SQLException {
        Connection c=DriverManager.getConnection("jdbc:oracle:thin:@//localhost:1521/XE",user,password);
        c.setAutoCommit(false);return c;
    }
    static void call(Connection c,String method,String student,int discipline,int grade)throws SQLException {
        String args=method.equals("delete_grade")?"?,?":"?,?,?,date '2026-10-20'";
        try(CallableStatement s=c.prepareCall("begin UNIVERSITY_PROJECT.TEACHER_GRADING."+method+"("+args+"); end;")) {
            s.setString(1,student);s.setInt(2,discipline);if(!method.equals("delete_grade"))s.setInt(3,grade);s.execute();
        }
    }
    static int error(Connection c,String sql)throws SQLException {
        try(Statement s=c.createStatement()){s.execute(sql);return 0;}catch(SQLException e){return e.getErrorCode();}
    }
    static Set<Integer> assigned(Connection owner,int teacher)throws SQLException {
        Set<Integer> ids=new HashSet<>();
        try(PreparedStatement s=owner.prepareStatement("select curriculum_id from discipline_teachers where teacher_id=?")) {
            s.setInt(1,teacher);try(ResultSet r=s.executeQuery()){while(r.next())ids.add(r.getInt(1));}
        }return ids;
    }
    static Map<String,int[]> gradebook(Connection c)throws SQLException {
        Map<String,int[]> rows=new HashMap<>();
        try(CallableStatement s=c.prepareCall("begin UNIVERSITY_PROJECT.TEACHER_GRADING.read_grades(?); end;")) {
            s.registerOutParameter(1,-10);s.execute();
            try(ResultSet r=(ResultSet)s.getObject(1)) {
                while(r.next()){
                    String key=r.getString("FACULTY_NUMBER")+"/"+r.getInt("DISCIPLINE_ID");
                    if(rows.put(key,new int[]{r.getInt("GRADE_VALUE"),r.getInt("GRADING_TEACHER_ID"),r.getInt("DISCIPLINE_ID"),r.getInt("CURRICULUM_ID")})!=null)
                        throw new SQLException("Duplicate academic row");
                }
            }
        }return rows;
    }
    static String snapshot(Connection c)throws SQLException {
        try(Statement s=c.createStatement();ResultSet r=s.executeQuery(
            "select dbms_xmlgen.getxml('select * from grades order by faculty_number,curriculum_id') from dual")) {
            r.next();return r.getString(1);
        }
    }
    public static void main(String[] ignored)throws Exception {
        Class.forName("oracle.jdbc.OracleDriver");BufferedReader in=new BufferedReader(new InputStreamReader(System.in,"UTF-8"));
        String ownerPassword=in.readLine();String[] passwords=new String[6];for(int i=0;i<6;i++)passwords[i]=in.readLine();
        try(Connection owner=connect("UNIVERSITY_PROJECT",ownerPassword)) {
            ownerPassword=null;String baseline=snapshot(owner);
            check(error(owner,"begin dbms_output.put_line(TEACHER_GRADING.current_teacher_id); end;")==20100,
                "Owner connection is not mistaken for a teacher login");
            for(int id=1;id<=6;id++) {
                try(Connection teacher=connect("UP_TEACHER_"+id,passwords[id-1])) {
                    Set<Integer> own=assigned(owner,id);
                    try(CallableStatement s=teacher.prepareCall("begin ?:=UNIVERSITY_PROJECT.TEACHER_GRADING.current_teacher_id; end;")) {
                        s.registerOutParameter(1,Types.NUMERIC);s.execute();check(s.getInt(1)==id,"Teacher "+id+" is resolved from authenticated SESSION_USER");
                    }
                    Map<String,int[]> before=gradebook(teacher);boolean filtered=true;
                    for(int[] row:before.values())filtered&=own.contains(row[3]);
                    check(filtered&&!before.isEmpty(),"Teacher "+id+" reads only assigned courses with no duplicate grades");
                    String selected=before.keySet().iterator().next();int ownId=before.get(selected)[2];
                    call(teacher,"update_grade",selected.split("/")[0],ownId,5);
                    int[] updated=gradebook(teacher).get(selected);
                    check(updated[0]==5&&updated[1]==id,"Teacher "+id+" can grade its own course and cannot choose another identity");
                    teacher.rollback();
                    try(PreparedStatement s=owner.prepareStatement("select g.faculty_number,c.discipline_id from grades g join curriculum c on c.curriculum_id=g.curriculum_id where not exists(select 1 from discipline_teachers dt where dt.curriculum_id=c.curriculum_id and dt.teacher_id=?) and rownum=1")) {
                        s.setInt(1,id);try(ResultSet r=s.executeQuery()) {
                            if(!r.next())throw new IllegalStateException("No unassigned context fixture");
                            check(error(teacher,"begin UNIVERSITY_PROJECT.TEACHER_GRADING.update_grade('"+r.getString(1)+"',"+r.getInt(2)+",5,date '2026-10-20'); end;")==20102,
                                "Teacher "+id+" cannot grade an unassigned specialty/course context");
                        }
                    }
                    int denied=error(teacher,"select * from UNIVERSITY_PROJECT.grades");
                    check(denied==942||denied==1031,"Teacher "+id+" has no direct base-table access");
                    check(error(teacher,"begin UNIVERSITY_PROJECT.UNIVERSITY_API.set_grade('00010001',1,5,date '2026-10-20',1); end;")==6550,
                        "Teacher "+id+" has no access to the administrator API or supplied teacher IDs");
                }
            }
            try(Connection t1=connect("UP_TEACHER_1",passwords[0]);Connection t2=connect("UP_TEACHER_2",passwords[1]);Connection t3=connect("UP_TEACHER_3",passwords[2])) {
                check(error(t3,"begin dbms_session.set_identifier('UP_TEACHER_1'); end;")==0&&
                    error(t3,"begin UNIVERSITY_PROJECT.TEACHER_GRADING.update_grade('00010001',1,5,date '2026-10-20'); end;")==20102,
                    "CLIENT_IDENTIFIER cannot spoof the grading teacher");
                check(error(t3,"alter session set current_schema=UNIVERSITY_PROJECT")==0&&
                    error(t3,"begin TEACHER_GRADING.update_grade('00010001',1,5,date '2026-10-20'); end;")==20102,
                    "CURRENT_SCHEMA cannot spoof SESSION_USER");
                call(t1,"insert_grade","00010007",1,4);
                check(gradebook(t1).get("00010007/1")[1]==1,"Teacher INSERT stores the actual authenticated grading teacher");
                call(t1,"delete_grade","00010007",1,0);
                check(!gradebook(t1).containsKey("00010007/1"),"Teacher DELETE works only within its assigned course and minimum counts");
                t1.rollback();
                check(error(t1,"begin UNIVERSITY_PROJECT.TEACHER_GRADING.insert_grade('00010001',1,5,date '2026-10-20'); end;")==20061,
                    "One student-course grade remains unique across teachers");
                check(error(t1,"begin UNIVERSITY_PROJECT.TEACHER_GRADING.update_grade('MISSING',1,5,date '2026-10-20'); end;")==20141,
                    "Teacher UPDATE rejects a missing grade");
                call(t1,"update_grade","00010001",1,5);
                check(error(t2,"begin UNIVERSITY_PROJECT.TEACHER_GRADING.update_grade('00010007',4,4,date '2026-10-20'); end;")==54,
                    "Different authenticated teachers cannot race past writer locks");
                t1.rollback();call(t2,"update_grade","00010007",4,4);
                check(gradebook(t2).get("00010007/4")[1]==2,"Authorized teacher succeeds after the first transaction releases its lock");
                t2.rollback();
                int sa;
                try(Statement s=owner.createStatement();ResultSet r=s.executeQuery("select discipline_id from disciplines where discipline_name=unistr('\\0421\\0410')")){r.next();sa=r.getInt(1);}
                call(t2,"update_grade","KST-DEMO",sa,5);
                check(gradebook(t2).get("KST-DEMO/"+sa)[1]==2,"Teacher 2 may grade SA for KST in semester 4");
                t2.rollback();
                check(error(t2,"begin UNIVERSITY_PROJECT.TEACHER_GRADING.update_grade('SIT-DEMO',"+sa+",5,date '2026-10-20'); end;")==20102,
                    "Same teacher and catalogue course cannot authorize SA for SIT in semester 6");
                Map<String,int[]> saRows=gradebook(t1);
                check(saRows.containsKey("SIT-DEMO/"+sa)&&saRows.containsKey("KST-DEMO/"+sa),
                    "Teacher 1 explicitly assigned to both specialties can read both SA contexts");
            }
            check(baseline.equals(snapshot(owner)),"All grade values, dates, student keys and teacher identities restored after testing");
            System.out.println("TEACHER_AUTHORIZATION_PASSED: "+passed+" checks; six real authenticated teacher accounts");
        }finally{Arrays.fill(passwords,null);}
    }
}
