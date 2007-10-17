# written by Yutaka konishi
# 2007/05/24
require 'kconv'
require 'rexml/document'
require 'net/http'

class LearningController < ApplicationController
model :user
model :ent_module
model :ent_seq
model :ent_test
model :ent_question
model :module_log
model :seq_log
model :level_log
model :operation_log
model :action_log
model :test_log
model :question_log
model :rule_search_time_log
before_filter :login_required

  #前回の続きを提示
  def index
    user = User.find(session[:user].id)
    #学習シーケンシングログを更新：Update SEQID
    seqlog = SeqLog.new
    seqlog[:ent_seq_id] = @params[:id]
    user.seq_log << seqlog

    unless seqlog.save
      flash[:notice] = "SEQ Log テーブルの更新に失敗"
      return
    end
    
    #next redirect(Query To Rule Engine)
    cur_mod_id = ModuleLog.getCurrentModule(session[:user].id , SeqLog.getCurrentId(session[:user].id) )

    redirect_to :action => 'next'

    #if cur_mod_id == -1
    #  redirect_to :action => 'next'
    #else
    #  redirect_to :action => 'view'
    #end
  end
  
  #テスト結果問い合わせ DBのログに追加処理
  def examCommit
    # テスト結果を取得
    http = Net::HTTP.new('localhost' , 80)
    req = Net::HTTP::Get.new("/~learn/cgi-bin/prot_test/adel_exam.cgi?mode=result")
    res = http.request(req)
    res_buff = res.body.split(/,/)
      
    #result [["q_id","得点"], ... ]
    result = []
    res_buff.each do |t|
      result.push t.split(/:/)
    end
    
    #　合計点を計算
    sum = 0
    result.each do |t|
      sum += t[1].to_i
    end
    
    #問題ごとの結果を問題ログに格納する(未実装)


    #テストIDを取得
    test_name = @params[:testname]
    testID = EntTest.find(:first,:conditions=>"test_name = '#{test_name}'")
    #現在のシーケンシングIDとモジュールIDを取得
    seqID = SeqLog.getCurrentId(session[:user].id)
    moduleID = ModuleLog.getCurrentModule(session[:user].id , seqID)
    #ログに追加
    testlog = TestLog.new
    testlog[:user_id] = session[:user].id
    testlog[:ent_seq_id] = seqID
    testlog[:ent_module_id] = moduleID
    testlog[:ent_test_id] = testID[:id]
    testlog[:sum_point] = sum
    
    # ログ作成
    TestLog.transaction do
      testlog.save!
    end

    # nextリダイレクト
    redirect_to :action => 'next'
  end

  #next コマンド 処理
  def next
    operation_event("next","-")
  end
  #学習者レベル変更コマンド処理
  def changeLv
    operation_event("changeLv",@params[:arg])
  end
  # 目次項目選択コマンド処理
  def toc
    operation_event("toc",@params[:arg])
  end
  # 教材提示アクション
  def view
    @username = "#{session[:user].firstname} #{session[:user].lastname}"
    makeView(ModuleLog.getCurrentModule(session[:user].id , SeqLog.getCurrentId(session[:user].id) ))
    
    #ログインユーザのインスタンスを取得
    user = User.find(session[:user].id)

    "123".to_i
    #PL/Perl 呼び出し後に時間を記録
    time_log = RuleSearchTimeLog.new
    time_log[:user_id] = user[:id]
    time_log[:time_name] = 'after_view'
    time_log[:time_value] = Time.now
    time_log.save
  end
  
# 内部処理用メソッド
protected

  # 操作Event　処理
  def operation_event(ope_code,e_arg)
    #ログインユーザのインスタンスを取得
    user = User.find(session[:user].id)
    cur_seq_id = SeqLog.getCurrentId(user[:id])

    #PL/Perl 呼び出し前に時間を記録
    time_log = RuleSearchTimeLog.new
    time_log[:user_id] = user[:id]
    time_log[:time_name] = 'before_perl'
    time_log[:time_value] = Time.now
    time_log.save

    ope_log = OperationLog.new
    # 操作コード ログに記録)
    ope_log[:operation_code] = ope_code
    # 操作識別コード　設定
    ope_log[:dis_code] = Time.now.to_i
    # Event引数　設定
    ope_log[:event_arg] = e_arg
    # テーブル間の関連付け
    ope_log[:ent_seq_id] = cur_seq_id
    ope_log[:user_id] = user[:id]
    
    OperationLog.transaction do
      ope_log.save!
      
      # Action 実行
      if action_array_obj = getActionCode(ope_log)
        execAction(user,action_array_obj)
      else
        flash[:notice]="アクションコードの取得に失敗しました。"
      end
    end
    
    #PL/Perl 呼び出し後に時間を記録
    time_log = RuleSearchTimeLog.new
    time_log[:user_id] = user[:id]
    time_log[:time_name] = 'after_perl'
    time_log[:time_value] = Time.now
    time_log.save

    redirect_to :action=>'view'
  end

  # アクションコード取得 メソッド
  def getActionCode(table_obj)
    where = "user_id = :user_id AND dis_code = :dis_code"
    value = {:user_id =>"#{session[:user].id}", :dis_code => "#{table_obj.dis_code}"}
    # アクションコード取得失敗 -> 最大5秒間待つ
    for i in 1..10
      sleep 0.5
      if action_array_obj = ActionLog.find(:all,:conditions=>[where,value],:order=>"id")
        return action_array_obj
      else
        next
      end
    end
    
    return nil
  end
  
  
  # アクション実行メソッド
  def execAction(user,action_array_obj)
    #アクション実行
    action_array_obj.each do |action_obj|
      case action_obj[:action_code]
      when /view/           # 教材モジュール提示
        
        # ログを追加
        mod_log = ModuleLog.new
        
        if /end/ =~ action_obj[:action_value]
          mod_log[:ent_module_id] = -1
        else
          ent_mod = EntModule.find(:first,:conditions=>"module_name = '#{action_obj[:action_value]}'")
          mod_log[:ent_module_id] = ent_mod[:id]
        end

        # シーケンシングと学習者のIDを関連付ける
        cur_seq = SeqLog.getCurrentId(user[:id])
        mod_log[:ent_seq_id] = cur_seq
        mod_log[:user_id] = user[:id]
        # 保存
        mod_log.save!

      when /retryall/       # 全体を再学習
      when /exit/           # 学習の終了
      when /changeLv/       # 学習者レベルの変更
        lev_log = LevelLog.new
        cur_seq = SeqLog.getCurrentId(user[:id])

        # シーケンシングと学習者のIDを関連付ける
        lev_log[:level] = action_obj[:action_value]
        lev_log[:ent_seq_id] = cur_seq
        lev_log[:user_id] = user[:id]
        #保存
        lev_log.save!
      when /msg/          # メッセージの送信
      when /assist/         # 補助教材の提示
      when /false/          # 実行するアクション無し
      end
    end
  end
  
  # 画面生成メソッド
  def makeView(mod_id)
    view_mod = EntModule.find(:first,:conditions=>"id = #{mod_id}")
    if view_mod
      @bodystr_html = ""
      node_array = GetXTDLNodeIDs(view_mod[:module_name].to_s)
      @bodystr_html = GetXTDLSources(node_array)
    else
      @bodystr_html = "<h2>学習を終了します.</h2>"
    end

    
    # 目次項目提示プロセス
    seq_id = SeqLog.getCurrentId(session[:user].id)
    if seq_id != -1
      ent_seq = EntSeq.find(seq_id)
      # buffList: [[mod_id , xtdl_id] , ........]
      buffList = []
      seq_src = ent_seq[:seq_src].gsub(/(\s|\n)/,'').split(/\./)
      i =0
      while i < seq_src.length
        /toc\(\s*(.+?),.*\)/ =~ seq_src[i]
        if $1
          # node_array [ [ resource_name , [res_id,...]], ... ]
          node_array = GetXTDLNodeIDs($1)
          buffList << [$1 , node_array[0] ]
        end
        i+=1
      end
      #tocList: [[mod_id , title name] , ........]
      @tocList = []
      # リソースからタイトル属性の値を抜く
      buffList.each do |buff|
        @tocList << [buff[0] , GetElementTitle(buff[1])]
      end
    end
  end

  def GetElementTitle(node_res_ids)
    http = Net::HTTP.new('localhost' , 8080)
    resource_name = node_res_ids[0]
    node_id = node_res_ids[1][0]
    # XML-DB から指定のXTDLリソースを取得
    req = Net::HTTP::Get.new("/exist/rest/db/adel_v2/xtdl_resources/#{resource_name}.xml?_query=//*[@id=%22#{node_id}%22]")
    res = http.request(req)
    
    doc = REXML::Document.new res.body
    elem = doc.elements["//*[@id='#{node_id}']"]
    if elem == nil
      return node_id
    else
      title = elem.attributes["title"]
      if title != ""
        return title
      else
        return "no title"
      end
    end
  end


  # 教材モジュールから提示すべき教材ノードIDを取得
  def GetXTDLNodeIDs(ent_module_name)
    # 学習者DBから教材モジュール　を取得
    ent_mod = EntModule.find(:first,:conditions=>"module_name = '#{ent_module_name}'")
    #モジュールからのrefs抽出
    doc = REXML::Document.new ent_mod[:module_src]
    doc = doc.elements["/module"]
    # node_array [ [ resource_name , [res_id,...]], ... ]
    node_array = []
    # 現在学習中の学習シーケンシングIDを取得
    # 現在の学習者レベルを取得
    cur_level = LevelLog.getCurrentLevel(session[:user].id , SeqLog.getCurrentId(session[:user].id) )
    
    # 提示すべきIDを取得
    doc.each_element { |elem_block|
      elem_block.each_element { |elem_node|
        level_array = elem_node.attributes["level"].split(/,/)
        level_array.each do |level|
          if /#{cur_level}|\*/ =~ level
            node_array.push [ elem_node.attributes["resource"], elem_node.attributes["refs"].split(/,/)]
            break
          end
        end
      }
    }
    return node_array
  end

  
  # 教材ノードから提示すべきHTMLソースを取得
  def GetXTDLSources(node_id_array)
    str_buff = ""
    # XML-DB(eXist)から 教材モジュール を取得
    http = Net::HTTP.new('localhost' , 8080)

    node_id_array.each do |node_res_ids|
      resource_name = node_res_ids[0]
      node_res_ids[1].each do |node_id|
        # XML-DB から指定のXTDLリソースを取得
        req = Net::HTTP::Get.new("/exist/rest/db/adel_v2/xtdl_resources/#{resource_name}.xml?_query=//*[@id=%22#{node_id}%22]")
        res = http.request(req)
        
        # DOM を生成
        doc = REXML::Document.new res.body
        doc = doc.elements["//*[@id='#{node_id}']"]
        str_buff += XTDLNodeSearch(doc)
      end
    end
    
    return str_buff
  end

  # 再帰的にノードを探索
  def XTDLNodeSearch(dom_obj)
    # 意味要素　配列
    semantic_elem_array = ["explanation","example","illustration","definition","program","algorithm","proof","simulation"]


    str_buff = ""
    flag = false # 判定フラグ
    if dom_obj.name["section"] ## section 要素ならば
      if dom_obj.attributes["title"] != ""
        str_buff += "<h1>" + dom_obj.attributes["title"].toutf8 + "</h1>"
      else
        str_buff += "<br /><br />"
      end
      dom_obj.each_element do |elem|
        str_buff += XTDLNodeSearch(elem)
      end
    elsif dom_obj.name["examination"] then ## テスト記述要素ならば
      # テスト記述要素以下をすべてテスト機構にPost
      http = Net::HTTP.new('localhost' , 80)
      req = Net::HTTP::Post.new("/~learn/cgi-bin/prot_test/adel_exam.cgi")
      res = http.request(req,"&mode=set&src=" + dom_obj.to_s)
      str_buff += res.body

      testid = dom_obj.attributes["id"]
    
      str_buff += "<br /><br /><form method=\"post\" action=\"/adel_v2/public/learning/examCommit?testname=#{testid}\" class=\"button-to\"><div><input type=\"submit\" value=\"Commit\" /></div></form>"

    else ## 意味要素　ならば
      if dom_obj.attributes["title"] != ""
        str_buff += "<h2>" + dom_obj.attributes["title"].toutf8 + "</h2>"
      else
        str_buff += "<br /><br />"
      end
      # 子はHTML？意味要素？
      semantic_elem_array.each do |semantic_elem|
        if dom_obj.elements["./#{semantic_elem}"]
          flag = true
        end
      end
      
      if flag
        # 意味要素の場合
        dom_obj.each_element do |elem|
          str += XTDLNodeSearch(elem)
        end
      else
        # HTMLの場合
        dom_obj.each do |elem|
          str_buff += elem.to_s.toutf8
        end
      end
    end
    
    return str_buff
  end


end
