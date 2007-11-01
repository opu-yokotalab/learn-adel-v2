require File.dirname(__FILE__) + '/../test_helper'
require 'learning_controller'

# Re-raise errors caught by the controller.
class LearningController; def rescue_action(e) raise e end; end

class LearningControllerTest < Test::Unit::TestCase
  def setup
    @controller = LearningController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
