// 2005/10/25
// Java��Prolog�Ȥ�Ϣ��
// shoji

import com.kprolog.plc.*;
public class ExecPlc{
    
    public ExecPlc(String args[]){
	Plc.startPlc(args);
    }

    public ExecPlc(String args[],String filename){
	new ExecPlc(args).reloadFile(filename);
    }

    public void reloadFile(String filename){
	Plc.exec("reconsult("+filename+").");
    }

    public void loadFile(String filename){
	Plc.exec("consult("+filename+").");
    }

    public void exec(String command){
	Plc.exec(command);
    }

    //��礻?
    public boolean find(String functor,Object[] args){
	Plc goal=new Plc(functor,args);
	return goal.call();
    }

    public static void main(String args[]){
	ExecPlc exeplc = new ExecPlc(args,"test.pl");
	exeplc.find("test",new Object[] {exeplc});
    }
}
