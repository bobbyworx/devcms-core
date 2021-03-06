require File.expand_path('../../test_helper.rb', __FILE__)

# Functional tests for the +ForumsController+.
class ForumsControllerTest < ActionController::TestCase
  self.use_transactional_fixtures = true

  test 'should show forum' do
    get :show, id: forums(:bewoners_forum).id
    assert_response :success
    assert assigns(:forum)
    assert_equal nodes(:bewoners_forum_node), assigns(:node)
  end
end
