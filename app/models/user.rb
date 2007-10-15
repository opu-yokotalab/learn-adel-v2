# modificated by Yutaka Konishi
# 2007/05/23
class User < ActiveRecord::Base
  include LoginEngine::AuthenticatedUser
  # all logic has been moved into login_engine/lib/login_engine/authenticated_user.rb

  # append by Yutaka Konishi
  has_many :action_log
  has_many :seq_log

end

