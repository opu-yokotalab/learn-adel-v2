class EntModule < ActiveRecord::Base
  has_many :module_log
  has_many :test_log

  validates_uniqueness_of :module_name, :message=>"その識別名は既に使用されています。"
end
