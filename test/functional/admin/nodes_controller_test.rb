require File.expand_path('../../../test_helper.rb', __FILE__)

class Admin::NodesControllerTest < ActionController::TestCase
  self.use_transactional_fixtures = true

  def test_should_deny_access_after_demote
    users(:sjoerd).demote!
    login_as :sjoerd
    get :index
    assert_response :redirect
  end
  
  def test_should_show_tree_from_root
    login_as :sjoerd
    get :index
    assert_response :success
    assert_equal Node.root, assigns(:root_node)
  end

  def test_should_show_tree_from_specified_node
    login_as :sjoerd
    get :index, :node => nodes(:devcms_news_node).id
    assert_response :success
    assert_equal nodes(:devcms_news_node), assigns(:root_node)
  end

  def test_should_return_child_nodes_for_json
    login_as :sjoerd
    get :index, :node => Node.root.id, :format => 'json'
    assert_response :success
    assert_equal Node.root.children, assigns(:nodes)
  end

  def test_should_insert_node_into_parent
    login_as :sjoerd
    s = nodes(:not_hidden_section_node)
    p = nodes(:about_page_node)
    xhr :put, :move, :id => p.id, :parent => s.id
    assert_response :success
  end

  def test_should_prepend_node_to_sibling
    login_as :sjoerd
    node_to_move = Node.root.children[4]
    new_sibling = Node.root.children.first
    xhr :put, :move, :id => node_to_move.id, :next_sibling => new_sibling.id
    assert_response :success
  end

  def test_move_should_return_error
    login_as :sjoerd
    xhr :put, :move, :id => Node.root.id, :parent => Node.root.id
    assert_response :error
  end

  def test_move_should_require_parent_or_sibling_id
    login_as :sjoerd
    xhr :put, :move, :id => Node.root.children.first.id
    assert_response :precondition_failed
  end

  def test_should_destroy_node
    login_as :sjoerd
    assert_difference('Node.count', -1) do
      delete :destroy, :id => Node.root.children.first
      assert_response :success
    end
  end

  def test_should_make_node_global_frontpage
    login_as :sjoerd
    put :make_global_frontpage, :id => nodes(:economie_section_node).id, :format => 'json'
    assert_response :success
    assert_equal nodes(:economie_section_node), Node.global_frontpage
  end

  def test_should_not_make_hidden_node_global_frontpage
    login_as :sjoerd
    nodes(:economie_section_node).update_attribute(:hidden, true)
    put :make_global_frontpage, :id => nodes(:economie_section_node).id, :format => 'json'
    assert_response :precondition_failed
    assert_not_equal nodes(:economie_section_node).id, Node.global_frontpage
  end

  def test_privileged_user_should_be_redirected_to_admin_root
    login_as :editor
    delete :destroy, :id => nodes(:root_section_node).id
    assert_response 403
  end

  def test_normal_user_should_be_redirected_to_site_root
    login_as :normal_user
    get :index
    assert_redirected_to root_path
  end
  
  def test_should_get_previous_diffed_for_approved_page_with_new_same_as_previous
    login_as :sjoerd
    get :previous_diffed, :id => nodes(:about_page_node).id
    assert_response :success    
    assert assigns(:content)
    assert assigns(:previous_content)
    assert_equal assigns(:content), assigns(:previous_content)
  end    

  def test_should_sort_children
    login_as :arthur
    xhr :put, :sort_children, :id => nodes(:economie_section_node).id
    assert_response :success
  end

  def test_should_count_children
    login_as :arthur
    xhr :get, :count_children, :id => nodes(:economie_section_node).id

    assert_response :success
    assert_equal nodes(:economie_section_node).children.count.to_s, @response.body
  end

  def test_should_get_bulk_edit
    login_as :arthur

    get :bulk_edit, :ids => [ nodes(:root_section_node).id, nodes(:economie_section_node).id ]
    assert_response :success

    assert assigns(:nodes).include?(nodes(:root_section_node))
    assert assigns(:nodes).include?(nodes(:economie_section_node))
  end

  def test_should_bulk_update_nodes
    login_as :arthur

    node1 = nodes(:root_section_node)
    node2 = nodes(:economie_section_node)

    category1 = categories(:category_blaat)
    category2 = categories(:category_foo)

    put :bulk_update, :ids => [ node1.id, node2.id ], :category_ids => [ category1.id, category2.id ], :has_categories => 1
    assert_response :success

    assert node1.categories.include?(category1)
    assert node1.categories.include?(category2)

    assert node2.categories.include?(category1)
    assert node2.categories.include?(category2)
  end

  def test_should_render_bulk_edit_when_bulk_update_fails
    login_as :arthur

    node1 = nodes(:root_section_node)
    node2 = nodes(:economie_section_node)

    category1 = categories(:category_blaat)
    category2 = categories(:category_foo)

    Node.expects(:bulk_update => false)

    put :bulk_update, :ids => [ node1.id, node2.id ], :category_ids => [ category1.id, category2.id ]
    assert_template 'edit'
  end

end
