require File.dirname(__FILE__) + '/../test_helper'

class ContactFormsControllerTest < ActionController::TestCase
  self.use_transactional_fixtures = true

  def test_should_get_show
    cf = contact_forms(:help_form)
    get :show, :id => cf.id
    assert_response :success
    assert_equal cf, assigns(:contact_form)
    assert assigns(:contact_form_fields)
  end
  
  def test_should_create_response_with_response_fields
    @help_form = contact_forms(:help_form)
    @help_form.send_method = ContactForm::SEND_METHOD_DATABASE
    @help_form.save
    assert_not_nil @help_form
    
    @name = contact_form_fields(:name)
    @email_address = contact_form_fields(:email_address)
    @phone_number = contact_form_fields(:phone_number)
    @question = contact_form_fields(:question)
    
    
    assert_difference('Response.count', 1) do
      assert_difference('ResponseField.count', 4) do
        post :send_message, :id => @help_form.id, 
          :contact_form_field => {@name.id.to_s => 'Henk', 
            @email_address.id.to_s => 'henk@gmail.com', 
            @phone_number.id.to_s => '+31(0)6',
            @question.id.to_s => 'What is the answer to the question of life, the universe and everything?'}
        assert_response :success
      end
    end
  end
    
  def test_should_not_create_response_with_response_fields
    @help_form = contact_forms(:help_form)
    @help_form.send_method = ContactForm::SEND_METHOD_MAIL
    @help_form.save
    assert_not_nil @help_form
    
    @name = contact_form_fields(:name)
    @email_address = contact_form_fields(:email_address)
    @phone_number = contact_form_fields(:phone_number)
    @question = contact_form_fields(:question)
    
    
    assert_no_difference('Response.count') do
      assert_no_difference('ResponseField.count') do
        post :send_message, :id => @help_form.id, 
          :contact_form_field => {@name.id.to_s => 'Henk', 
            @email_address.id.to_s => 'henk@gmail.com', 
            @phone_number.id.to_s => '+31(0)6',
            @question.id.to_s => 'What is the answer to the question of life, the universe and everything?'}
        assert_response :success
      end
    end
    
  end


end
