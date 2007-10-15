// Yutaka Konishi authed
// 2006/10/13
import java.io.*;
import javax.xml.parsers.*;
import org.w3c.dom.*;

public class LearnerObject{
    private JDBCConn jdbcConn;
    private String cfg_path;
    private String user_id;
    private String ent_seq_id;

    public LearnerObject(String cfg_path,String user_id,String ent_seq_id){
    	this.cfg_path=cfg_path;
	this.user_id=user_id;
	this.ent_seq_id=ent_seq_id;
    }

    public Object[] toArray(){
    	Object[] li,moduleList,testResult,level;
	jdbcConn = new JDBCConn(cfg_path);
	moduleList = new Object[] {"moduleList",jdbcConn.getModuleList(user_id,ent_seq_id)};
	testResult = new Object[] {"testResult",jdbcConn.getTestResult(user_id,ent_seq_id)};
	level =new Object[] {"level",jdbcConn.getLevel(user_id , ent_seq_id)};
	li = new Object[] {moduleList,testResult,level};
	return li;
    }
    
    public String getSeqPath(String ent_seq_id){
	jdbcConn = new JDBCConn(cfg_path);
	String FName = jdbcConn.getSeqFName(ent_seq_id);
	String Path = "../" + FName;
	return Path;
    }

    public static void main(String args[]){
    	Object[] obj=new LearnerObject("seq.cfg",args[0],args[1]).toArray();
	Object[] obj2=(Object[])obj[0];
	Object[] obj3=(Object[])obj2[1];
	for(int i=0;i<obj3.length;i++){
	    System.out.println("list " + i + ": " + obj3[i]);
	}
    }
}
