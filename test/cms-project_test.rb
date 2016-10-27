ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"
require "fileutils"

require_relative "../cms.rb"

class AppTest < Minitest::Test
  include Rack::Test::Methods
  
  def app
    Sinatra::Application
  end
  
  def setup
    FileUtils.mkdir_p(data_path)
  end
  
  def teardown
    FileUtils.rm_rf(data_path)
  end
  
  def create_document(name, content = "")
    File.open(File.join(data_path, name), "w") do |file| 
      file.write(content)
    end
  end
  
  def session
    last_request.env["rack.session"]
  end
  
  def signin_user #this is one way, the other is to set the rack.session see admin_session method 
    post "/user/signin", :user_name => "admin", :password => "secret"
  end
  
  def admin_session
    {"rack.session" => {:user_name => "admin" } }
  end
  
  
  def test_index
    create_document "about.md"
    create_document "changes.txt"
    get '/'
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "about.md"
    assert_includes last_response.body, "changes.txt"
  end
  
  def test_content_of_changes_document
    create_document "history.txt", "Ruby 0.95 released"
    get '/history.txt'
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Ruby 0.95 released"
  end
  
  def test_document_not_found
    get "/notafile.ext"
    assert_equal 302, last_response.status
    assert_equal "notafile.ext does not exist.", session[:message]
  end
  
  def test_editing_document
    create_document "changes.txt"
    #signin_user
    get "/changes.txt/edit",{}, admin_session
    assert_equal 200, last_response.status
    assert_includes last_response.body, "<textarea"
    assert_includes last_response.body, %q(<button type="submit")
  end
  
  def test_upddating_document
    signin_user
    post "/changes.txt", content: "new content"
    assert_equal 302, last_response.status
    assert_equal "changes.txt has been updated.", session[:message]
    
    get  "/changes.txt"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "new content"
  end
  
  def test_new_document_form
    signin_user
    get "/new"#, {}, admin_session
    assert_equal 200, last_response.status
    assert_includes last_response.body, "<input"
    assert_includes last_response.body, %q(<button type="submit") 
  end
  
  def test_create_new_file
    signin_user
    post "/create", {:file_name => "my_new_file.txt"},  admin_session
    assert_equal 302, last_response.status
    assert_equal "File my_new_file.txt created", session[:message]
    
    # alternatively running the redirect
    get last_response["Location"] #runs the redirect
    assert_includes last_response.body, "File my_new_file.txt created"
    
    #running index to check that the new file is in the index
    get "/"
    assert_includes last_response.body, "my_new_file.txt"
  end
  
  def test_delete_file
    create_document("to_be_deleted.txt")
    signin_user
    post "to_be_deleted.txt/delete"#, {}, admin_session 
    assert_equal 302, last_response.status
    assert_equal "to_be_deleted.txt has been deleted", session[:message]
    
    get last_response.body, "to_be_deleted.txt has been deleted"
    
    #checking that the file nolonger exists
    get "/"
    refute_includes last_response.body, "to_be_deleted.txt"
  end
  
  def test_get_signin_form
    get "/user/signin"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "<input"
    assert_includes last_response.body, %q(<label for="user_name">User Name</label>)
  end
  
  def test_successful_signin
    post "/user/signin", :user_name => 'admin', :password => 'secret'
    assert_equal 302, last_response.status 
    get last_response["Location"]
    assert_includes last_response.body, "Welcome to  CMS"
    assert_equal 200, last_response.status 
  end
  
  def test_successful_signin_alternate #using the rack env  
    post "/user/signin", :user_name => 'admin', :password => 'secret'
    assert_equal 302, last_response.status 
    assert_equal 'admin', session[:user_name]
    assert_equal "Welcome to  CMS", session[:message]
  end
    
  def test_invalid_password
    post "/user/signin", :user_name => 'admin', :password => '6767'
    assert_equal 200, last_response.status 
    assert_equal "Invalid Credentials", session[:message]
  end
  
  def test_invalid_username
    post "/user/signin", :user_name => 'adminee', :password => 'secret'
    assert_equal 200, last_response.status 
    assert_equal "Invalid Credentials", session[:message]
  end
  
end