% ECA ルール 2005/12/25 17:44
% 庄司成臣
%% 2006/8/4 拡張
%% modificated by Yutaka Konishi

% LI 
% [
%  ["moduleList",["start","mod_id","mod_id","mod_id"]] ,
%  ["testResult",[["test_id", "合計点"],["test_id", "合計点"]] ] ,
%  ["level", "1"]
% ]
% ModuleList ノード履歴(リスト)　
% TestResult テスト結果(ハッシュ)
% Level      レベル(文字)

% New イベントの引数(ハッシュ)
% [
%  ["to","更新されたデータ"],
%  ["test","更新されたテスト"],
%  ["level","レベル変更の要求:up or down"]
% ]

% ActionList アクション(ハッシュ) [["move","1"],["cheer","Fight!!"]]

%%%% for Java
%eca(Type,New,LI,ActionList,Ji).
call_eca(Type,New,LI,ActionList,Ji):-eca(Type,New,LI,ActionList),javaMethod(Ji,print(ActionList),_).

%%%% ECA
eca("next", _,LI,ActionList):-next_eca(LI, ActionList).
eca("toc",New,LI,ActionList):-toc_eca(New,LI, ActionList).
eca("update",New,LI,ActionList):-update_eca(New,LI, ActionList).
eca("changeLv",New,LI,ActionList):-changeLv_eca(New,LI, ActionList).

% 次のノードを要求
next_eca(LI, ActionList) :- 
	getCurrentModule(LI,From),next(From,To,LI,ArcAction),append(["move"],[To],Move),append([Move],ArcAction,ActionList).
% 目次から選ぶ
toc_eca(New, LI, ActionList) :- whereTo(New,MoveTo),toc(MoveTo ,LI , ArcAction),append(["move"],[MoveTo],Move),append([Move],ArcAction,ActionList).

% データ更新 移動無し
update_eca(New,LI, ActionList) :- whereUpdate(New,To),update(To, New, LI, ActionList).

% 難易度変更の要求
changeLv_eca(New, LI, ActionList):- chLvArg(New, Arg),change_Lv(Arg , LI ,ActionList).


%%%% アクセッサメソッド

%% モジュールリスト
% 現在のモジュール
getCurrentModule(LI,CurrentModule):- hash(LI,"moduleList",ModuleList),last(ModuleList,CurrentModule).
moduleMatch(LI,MatchModule):- getCurrentModule(LI,CurrentModule),MatchModule=CurrentModule.
moduleMember(LI,X):-hash(LI,"moduleList",ModuleList),member(X,ModuleList).

%% テスト結果
getTestPoint(LI,Key,Point):- hash(LI,"testResult",TestResult),hash(TestResult,Key,Point).
% 比較 (引数で与えた点数より高ければ真、低ければ偽)
testCompare(LI,Key,ComparePoint):- getTestPoint(LI,Key,Point),ComparePoint<Point.
% getTestCount(LI,Key,Count).

%% レベル
chLvArg(New ,Arg):- hash(New ,"level" , Arg).
getLevel(LI,Level):- hash(LI,"level",Level).
%マッチング
levelMatch(LI,MatchLevel):- getLevel(LI,Level),MatchLevel=Level.

%% 目次から選択
whereTo(New, MoveTo):- hash(New ,"to" ,MoveTo).

% update
getUpdatedTest(New,TestWhere):-hash(New,"test",TestWhere).
whereUpdate(New,To):-hash(New,"to",To).

%%%% ユーティリティ

% 連想リスト
hash(Hash,Key,Value):-member([Key,Value],Hash).

% List の結合
append([],Y,Y).
append([U|X],Y,[U|Z]):-append(X,Y,Z).

% List の最後の要素を求める
last(L, X) :- append(_, [X], L).

% each element
member(X,[X|_]).
member(X,[_|List]):-member(X,List).
