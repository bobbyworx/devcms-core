require File.dirname(__FILE__) + '/../test_helper'

class WeblogArchivesControllerTest < ActionController::TestCase
  self.use_transactional_fixtures = true

  def test_should_show_weblog_archive
    get :show, :id => weblog_archives(:devcms_weblog_archive).id
    assert_response :success
    assert assigns(:weblog_archive)
    assert_equal nodes(:devcms_weblog_archive_node), assigns(:node)
  end
  
end
