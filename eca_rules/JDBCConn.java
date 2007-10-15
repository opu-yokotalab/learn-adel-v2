import java.sql.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.io.FileReader;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.FileNotFoundException;

public class JDBCConn{
    private String DRIVER = "";
    private String HOSTNAME = "";
    private String DBNAME = "";
    private String USER = "";
    private String PASS = "";

    public JDBCConn(String cfgpath){
	HashMap env = loadenv(cfgpath);
	DRIVER = (String)env.get("driver");
	HOSTNAME = (String)env.get("hostname");
	DBNAME = (String)env.get("dbname");
	USER = (String)env.get("user");
	PASS = (String)env.get("pass");
    }
    
    public HashMap loadenv(String cfgpath){
	HashMap env = new HashMap();
	try{
	    FileReader fr = new FileReader(cfgpath);
	    BufferedReader br = new BufferedReader(fr);
	    String filestr=new String();
	    while((filestr = br.readLine())!=null){
		String[] strarray=filestr.split(" +");
		env.put(strarray[0],strarray[1]);
	    }
	}
	catch(FileNotFoundException e){
	    System.out.println("JDBCConn: no cfg file");
	}
	catch(IOException ie){
	    System.out.println("JDBCConn: can't open cfg file");
	}
	return env;
    }
    
    public Object[] getModuleList(String user_id,String ent_seq_id){
	// モジュール数を取得
    	ArrayList idList=this.jdbcConn("select ent_module_id from module_logs where user_id = '" + user_id + "' and ent_seq_id='" + ent_seq_id + "' order by id",1);
	ArrayList moduleList = new ArrayList(idList.size());
	if (idList.size()==0){
	    // ログが無ければ "start" を追加
	    moduleList.add("start");
	}else{
	    // モジュールの名前を取得
	    for(int i=0;i < idList.size();i++)
		moduleList.add(this.jdbcConn("select module_name from ent_modules where id = '" + idList.get(i).toString() + "'",1).get(0).toString());
	}
    	return moduleList.toArray();
    }
    
    public Object[] getTestResult(String user_id,String ent_seq_id){
	//　テスト結果のログを抽出
	// [[testid, point] , [testid , point],... ]の列を作る
	ArrayList idList = this.jdbcConn("select ent_test_id from test_logs where user_id = '" + user_id + "' and ent_seq_id = '" + ent_seq_id + "' group by ent_test_id",1);
	ArrayList testResultList = new ArrayList(idList.size());
	if(idList.size()==0){
	    // ログが無ければ何も返さない
	    return null;
	}else{
	    // テストのIDを取得
	    // テストのIDから最新の合計点数を取得
	    for(int i=0;i<idList.size();i++){
		ArrayList test_name = this.jdbcConn("select test_name from ent_tests where id = '" + idList.get(i).toString() + "' LIMIT 1",1);
		ArrayList sum_point = this.jdbcConn("select sum_point from test_logs where user_id = '" + user_id + "' and ent_seq_id = '" + ent_seq_id + "' and ent_test_id = '" + idList.get(i).toString() + "' order by id desc limit 1",1);
		
		Object[] buffObj = {test_name.get(0).toString(), Integer.parseInt(sum_point.get(0).toString())};
		testResultList.add(buffObj);
	    }
	    return testResultList.toArray();
	}
    }
    
    public String getLevel(String user_id, String ent_seq_id){
	// 変更の履歴数を取得
	String ret_str;
    	ArrayList idList=this.jdbcConn("select ent_level_id from level_logs where user_id = '" + user_id + "' and ent_seq_id='" + ent_seq_id + "' order by id desc",1);
	if(idList.size() == 0){
	    // ログがなければ初期値設定
	    ret_str = "1";
	}else{
	    // レベルを取得
	    ArrayList changeLevel = this.jdbcConn("select level from ent_levels where id = '" + idList.get(0).toString() + "'",1);
	    ret_str = changeLevel.get(0).toString();
	}
	return ret_str;
    }
    
    // 現在履修中の学習シーケンシングのファイル名を取得
    public String getSeqFName(String ent_seq_id){
	ArrayList fnameList = this.jdbcConn("select seq_fname from ent_seqs where id = '" + ent_seq_id + "'",1);
	if(fnameList.size() == 0){
	    return "None";
	}
	
	return fnameList.get(0).toString();
    }

    public ArrayList jdbcConn(String query,int column_size){
	Connection con = null;
	Statement stmt = null;
	ArrayList list = new ArrayList(); 
	try {
	    Class.forName (DRIVER);
	    con = DriverManager.getConnection (
					       "jdbc:postgresql://"+HOSTNAME+"/"+DBNAME,
					       USER,
					       PASS
					       );
	    stmt = con.createStatement ();
	    
	    ResultSet rs = stmt.executeQuery (query);
	    while ( rs.next () ) {
		if(column_size==1){
		    list.add(rs.getString (1));
		}
		else if(column_size==2){
		    Object[] one_row = {rs.getString (1),rs.getString(2)};
		    list.add(one_row);
		}
	    }
	    rs.close ();
	    stmt.close ();
	    con.close ();
	}catch(Exception e){
	   System.out.println("JDBCConn: DBaccess error");
	   e.printStackTrace();
	}
	return list;
    }




    // Prolog問い合わせ前後の時刻をDBに書き込む
    public void InsertTime(String user_id,String time_name){
	this.jdbcConnInsert("insert into rule_search_time_logs (user_id, time_name, time_value) VALUES('"+ user_id +"','"+ time_name +"','now')");
    }

    public void jdbcConnInsert(String query){
	Connection con = null;
	Statement stmt = null;
	try {
	    Class.forName (DRIVER);
	    con = DriverManager.getConnection (
					       "jdbc:postgresql://"+HOSTNAME+"/"+DBNAME,
					       USER,
					       PASS
					       );
	    stmt = con.createStatement ();	    
	    int rs = stmt.executeUpdate(query);

	    stmt.close ();
	    con.close ();
	}catch(Exception e){
	   System.out.println("JDBCConn: DBaccess error");
	   e.printStackTrace();
	}
    }

}
