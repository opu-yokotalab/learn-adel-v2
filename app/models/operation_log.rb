class OperationLog < ActiveRecord::Base
  belongs_to :ent_seq
  after_save :rule_evaluate
  
  def rule_evaluate
    # イベント取得
    ope_code = self[:operation_code]
    # SEQログから現在のECAルールを取得
    ent_seq = EntSeq.find(self[:ent_seq_id])
    seq_src = ent_seq[:seq_src]
    # 空白と改行の削除　→　.で分割
    seq_src = seq_src.gsub(/(\s|\n)/,'').split(/\./)
    
    # EcaRuleMatrixの作成
    seq_mat = makeEcaRuleMatrix(seq_src)

    # seq_mat データ構造
    # next or changeLv [Event,[EventArg1,EventArg2],[ActionList],[ConditionList]]
    # toc [Event,EventArg,[ActionList],[ConditionList]]
    # ActionList [[ActionCode,ActionValue],... ]
    # ConditionList [[Condition,Arg1,Arg2],... ]

    # ルールを評価
    # イベント毎に処理を分岐
    case ope_code
    when /next/    # 次の教材を要求するイベントの処理

      # 現在表示している教材モジュールを取得
      mod_id = ModuleLog.getCurrentModule(self[:user_id] , self[:ent_seq_id])      
      if mod_id != -1
        ent_mod = EntModule.find(mod_id)
        mod_name = ent_mod[:module_name]
      else
        mod_name = "start"
      end
      
      # conditionのマッチング
      n=0
      while n < seq_mat.length do
        if seq_mat[n][0] =~ /#{ope_code}/
            if seq_mat[n][1][0] =~ /#{mod_name}/
                if conditionMatching(seq_mat[n][3])
                  break
                end
            end
        end
        n+=1
      end

      actionList = Array.new
      # actionの決定
      if n < seq_mat.length
        actionList = seq_mat[n][2]
        if seq_mat[n][1][1] =~ /end/
          actionList.push("view,end")
        else
          actionList.push("view,#{seq_mat[n][1][1]}")
        end
      else
        actionList.push("false,-")
      end

    when /toc/      # 目次から選択イベントの処理
      # conditionのマッチング
      n=0
      while n < seq_mat.length do
        if seq_mat[n][0] =~ /#{ope_code}/
            if seq_mat[n][1] =~ /#{self[:event_arg]}/
                if conditionMatching(seq_mat[n][3])
                  break
                end
            end
        end
        n+=1
      end

      actionList = Array.new
      # actionの決定
      if n < seq_mat.length
        actionList = seq_mat[n][2]
        actionList.push("view,#{seq_mat[n][1]}")
      else
        actionList.push("false,-")
      end

    when /changeLv/      # レベル変更の要求のイベントの処理
      # conditionのマッチング
      n=0
      while n < seq_mat.length do
        if seq_mat[n][0] =~ /#{ope_code}/
            if seq_mat[n][1][0] =~ /#{self[:event_arg]}/
                if conditionMatching(seq_mat[n][3])
                  break
                end
            end
        end
        n+=1
      end

      actionList = Array.new
      # actionの決定
      if n < seq_mat.length
        actionList = seq_mat[n][2]
        actionList.push("changeLv,#{seq_mat[n][1][1]}")
      else
        actionList.push("false,-")
      end

    end


    # ActionLogテーブルに格納　トランザクションブロック
    ActionLog.transaction do
      i=0
      while i < actionList.length do
        code_value = actionList[i].split(/,/)
        action = ActionLog.new
        action[:user_id] = self[:user_id]
        action[:ent_seq_id] = self[:ent_seq_id]
        action[:action_code] = code_value[0]
        action[:action_value] = code_value[1]
        action[:dis_code] = self[:dis_code]
        action.save!
        i+=1
      end
    end
  end


  # ルールリスト作成  
  def makeEcaRuleMatrix(seq_src)
    seq_mat = Array.new
    # Parsing用の正規表現を定義
    opeReg = /(next|toc|changeLv)\((.+?),\[(.*?)\]\)(.*)/
    
    i=0
    while i < seq_src.length do
      eca_array = opeReg.match(seq_src[i]).to_a
      if (eca_array[1] == "next") || (eca_array[1] == "changeLv")
        event_values = eca_array[2].gsub(/\[|\]/,'').split(/,/)
      elsif eca_array[1] == "toc"
        event_values = eca_array[2]
      end
      
      #actionリスト取り出し
      actions = eca_array[3].split(/\],\[/)
      actions.each do |t|
        t.gsub!(/\[|\]/,'')
      end
      #conditionリスト取り出し
      conditions = eca_array[4]
      if conditions == ""
        # 条件が無いときは空リストを代入
        conditions = []
      else
        conditions.gsub!(/:-/,'')
        conditions.gsub!(/\),/,'::')
        conditions.gsub!(/\(/,',')
        conditions.gsub!(/\)/,'')
        conditions = conditions.split(/::/)
      end
      
      seq_mat.push([eca_array[1],event_values,actions,conditions])
      i += 1
    end

    return seq_mat
  end


  def conditionMatching(conditionList)
    n=0
    while n < conditionList.length do
      condition = conditionList[n].split(/,/)
      case condition[0]
      when /currentModule/
      when /moduleMember/
      when /moduleCount/
      when /(not|)testCompare/
        mod_id = ModuleLog.getCurrentModule(self[:user_id] , self[:ent_seq_id])
        cur_point = TestLog.getSumPoint(self[:user_id],self[:ent_seq_id],mod_id,condition[1])

        if condition[0] == "testCompare"
          # 現在の点数が指定より低ければfalse
          if cur_point < condition[2].to_i
            return false
          end
        elsif condition[0] == "nottestCompare"
          # not 反転
          # 現在の点数が指定より高ければfalse
          if cur_point > condition[2].to_i
            return false
          end
        end
      when /testTime/
      when /testCount/
      when /currentLevel/
        cur_level = LevelLog.getCurrentLevel(self[:user_id],self[:ent_seq_id])
        if cur_level != condition[1]
          # condition ミスマッチ
          return false
        end
      end
      n+=1
    end

    return true
  end


  validates_inclusion_of :operation_code, :in=>%w(next toc changeLv)
end
