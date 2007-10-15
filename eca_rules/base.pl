% ECA �롼�� 2005/12/25 17:44
% ��������
%% 2006/8/4 ��ĥ
%% modificated by Yutaka Konishi

% LI 
% [
%  ["moduleList",["start","mod_id","mod_id","mod_id"]] ,
%  ["testResult",[["test_id", "�����"],["test_id", "�����"]] ] ,
%  ["level", "1"]
% ]
% ModuleList �Ρ�������(�ꥹ��)��
% TestResult �ƥ��ȷ��(�ϥå���)
% Level      ��٥�(ʸ��)

% New ���٥�Ȥΰ���(�ϥå���)
% [
%  ["to","�������줿�ǡ���"],
%  ["test","�������줿�ƥ���"],
%  ["level","��٥��ѹ����׵�:up or down"]
% ]

% ActionList ���������(�ϥå���) [["move","1"],["cheer","Fight!!"]]

%%%% for Java
%eca(Type,New,LI,ActionList,Ji).
call_eca(Type,New,LI,ActionList,Ji):-eca(Type,New,LI,ActionList),javaMethod(Ji,print(ActionList),_).

%%%% ECA
eca("next", _,LI,ActionList):-next_eca(LI, ActionList).
eca("toc",New,LI,ActionList):-toc_eca(New,LI, ActionList).
eca("update",New,LI,ActionList):-update_eca(New,LI, ActionList).
eca("changeLv",New,LI,ActionList):-changeLv_eca(New,LI, ActionList).

% ���ΥΡ��ɤ��׵�
next_eca(LI, ActionList) :- 
	getCurrentModule(LI,From),next(From,To,LI,ArcAction),append(["move"],[To],Move),append([Move],ArcAction,ActionList).
% �ܼ���������
toc_eca(New, LI, ActionList) :- whereTo(New,MoveTo),toc(MoveTo ,LI , ArcAction),append(["move"],[MoveTo],Move),append([Move],ArcAction,ActionList).

% �ǡ������� ��ư̵��
update_eca(New,LI, ActionList) :- whereUpdate(New,To),update(To, New, LI, ActionList).

% ������ѹ����׵�
changeLv_eca(New, LI, ActionList):- chLvArg(New, Arg),change_Lv(Arg , LI ,ActionList).


%%%% �������å��᥽�å�

%% �⥸�塼��ꥹ��
% ���ߤΥ⥸�塼��
getCurrentModule(LI,CurrentModule):- hash(LI,"moduleList",ModuleList),last(ModuleList,CurrentModule).
moduleMatch(LI,MatchModule):- getCurrentModule(LI,CurrentModule),MatchModule=CurrentModule.
moduleMember(LI,X):-hash(LI,"moduleList",ModuleList),member(X,ModuleList).

%% �ƥ��ȷ��
getTestPoint(LI,Key,Point):- hash(LI,"testResult",TestResult),hash(TestResult,Key,Point).
% ��� (������Ϳ�����������⤱��п����㤱��е�)
testCompare(LI,Key,ComparePoint):- getTestPoint(LI,Key,Point),ComparePoint<Point.
% getTestCount(LI,Key,Count).

%% ��٥�
chLvArg(New ,Arg):- hash(New ,"level" , Arg).
getLevel(LI,Level):- hash(LI,"level",Level).
%�ޥå���
levelMatch(LI,MatchLevel):- getLevel(LI,Level),MatchLevel=Level.

%% �ܼ���������
whereTo(New, MoveTo):- hash(New ,"to" ,MoveTo).

% update
getUpdatedTest(New,TestWhere):-hash(New,"test",TestWhere).
whereUpdate(New,To):-hash(New,"to",To).

%%%% �桼�ƥ���ƥ�

% Ϣ�ۥꥹ��
hash(Hash,Key,Value):-member([Key,Value],Hash).

% List �η��
append([],Y,Y).
append([U|X],Y,[U|Z]):-append(X,Y,Z).

% List �κǸ�����Ǥ����
last(L, X) :- append(_, [X], L).

% each element
member(X,[X|_]).
member(X,[_|List]):-member(X,List).
