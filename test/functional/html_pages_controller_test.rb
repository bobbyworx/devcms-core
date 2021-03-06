require File.expand_path('../../test_helper.rb', __FILE__)

class HtmlPagesControllerTest < ActionController::TestCase
  self.use_transactional_fixtures = true

  test 'should show html page' do
    get :show, id: html_pages(:about_html_page)
    assert_response :success
    assert assigns(:html_page)
    assert_equal nodes(:about_html_page_node), assigns(:node)
  end
end
