// 2005/12/12 18:23
import com.kprolog.plc.*;
import java.util.ArrayList;

public class SeqTaste{
    private ExecPlc execplc;
    private String cfg_path;

    public SeqTaste(String seq_path,String seq_base,String cfg_path){
    	this.cfg_path = cfg_path;
	execplc = new ExecPlc(new String[] {"-g","80k","-l","40k"},seq_base);
	execplc.loadFile(seq_path);
    }

    public void print(Object[] array){
        String action="";
	
	for(int i=0;i<array.length;i++){
	    Object[] oneAction = (Object[])array[i];
	    for (int j=0;j<oneAction.length;j++){
		action += (String)oneAction[j];
		if (j!=oneAction.length-1) action+=",";
	    }
	    if (i!=array.length-1) action+=":";
	}
	System.out.println(action);
    }

    public void callECA(String type,String user_id,String ent_seq_id,Object[] newHash){
	Object[] lo = new LearnerObject(cfg_path,user_id,ent_seq_id).toArray();
       	boolean tf = execplc.find("call_eca",new Object[] {type,newHash,lo,null,this});
	if (!tf){
	    System.out.println("false");
	}
    }

    private Object[] parseNew(String newString){
    	Object[] newHash ;
	ArrayList list=new ArrayList();
	String[] newArray = newString.split(",");
	if(newArray.length%2!=1){
		for(int i=0;i<newArray.length;i+=2){
			list.add(new Object[] {newArray[i],newArray[i+1]});
		}
	}
	newHash = list.toArray();
	return newHash;
    }

    public static void main(String args[]){
	String cfg_path = args[0];
	String type = args[1];
	String newString = args[2];
	String user_id = args[3];
	String ent_seq_id = args[4];

	String seq_path;
	
	// 学習者情報データベース にアクセス
	// seqテーブルから実行すべきシーケンシングのファイル名を取得
	// ルール検索実行
	LearnerObject user = new LearnerObject(cfg_path,user_id,ent_seq_id);
	seq_path = user.getSeqPath(ent_seq_id);
	
	JDBCConn before_con = new JDBCConn(cfg_path);
	before_con.InsertTime(user_id,"before_prolog");

	SeqTaste seqTaste = new SeqTaste(seq_path,"base",cfg_path);
	Object[] newHash = seqTaste.parseNew(newString);
	seqTaste.callECA(type,user_id,ent_seq_id,newHash);

	JDBCConn after_con = new JDBCConn(cfg_path);
	after_con.InsertTime(user_id,"after_prolog");
    }
}
