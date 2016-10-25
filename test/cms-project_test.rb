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
    
    get last_response["Location"]

    assert_equal 200, last_response.status
    assert_includes last_response.body, "notafile.ext does not exist"
  end
  
  def test_editing_document
    create_document "changes.txt"
    get "/changes.txt/edit"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "<textarea"
    assert_includes last_response.body, %q(<button type="submit")
  end
  
  def test_upddating_document
    post "/changes.txt", content: "new content"
    assert_equal 302, last_response.status
    
    get last_response["Location"]
  
    
    assert_includes last_response.body, "changes.txt has been updated"

    get  "/changes.txt"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "new content"
  end
  
  def test_new_document_form
    get "/new"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "<input"
    assert_includes last_response.body, %q(<button type="submit") 
  end
  
  def test_create_new_file
    post "/create", :file_name => "my_new_file.txt"
    
    assert_equal 302, last_response.status
    
    get last_response["Location"]
    assert_includes last_response.body, "File my_new_file.txt created"
    
    get "/"
    assert_includes last_response.body, "my_new_file.txt"
  end
  
  def test_delete_file
    create_document("to_be_deleted.txt")
    
    post "to_be_deleted.txt/delete"
    assert_equal 302, last_response.status
    get last_response.body, "to_be_deleted.txt has been deleted"
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
    post "/user/authenticate", :user_name => 'admin', :password => 'secret'
    assert_equal 302, last_response.status 
    get last_response["Location"]
    assert_includes last_response.body, "Welcome to  CMS"
    assert_equal 200, last_response.status 
  end
    
  def test_invalid_password
    post "/user/authenticate", :user_name => 'admin', :password => '6767'
    assert_equal 200, last_response.status 
    assert_includes last_response.body, "Invalid Credentials"
  end
  
  def test_invalid_username
    post "/user/authenticate", :user_name => 'adminee', :password => 'secret'
    assert_equal 200, last_response.status 
    assert_includes last_response.body, "Invalid Credentials"
  end
  
end