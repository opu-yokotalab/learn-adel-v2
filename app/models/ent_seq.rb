class EntSeq < ActiveRecord::Base
  has_many :seq_log
  has_many :module_log
  has_many :level_log
  has_many :operation_log
  has_many :action_log
end
