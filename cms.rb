require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"
require "redcarpet"
require "pry"
require "pry-byebug"

#blogg http://cms-project.blogspot.com.au/
configure do
  enable :sessions
  set :session_secret, 'cmc-secret'
  #set :erb, :escape_html => true
end

def data_path
  if ENV["RACK_ENV"] == 'test'
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

get "/" do
  pattern = File.join(data_path,"*")
  @cms_files = Dir.glob(pattern).map do |path|
    File.basename(path)
  end
  erb :index
end

get "/new" do
  erb :new_file
end

post "/create" do
  filename = params[:file_name].to_s
  if filename.size == 0
    session[:message] = "You must enter a file name"
    status 422
    erb :new_file
  else
    file_path = File.join(data_path,params[:file_name])
    File.write(file_path, "")
    session[:message] = "File #{filename} created"
    redirect "/"
  end
end 

get "/:file_name" do
  if file_exists?
    retrieve_file_contents
    render_file
    erb :show_file
  else
    session[:message] = "#{params[:file_name]} does not exist."
    redirect "/"
  end
end

get "/:file_name/edit" do
  file = File.join(data_path,params[:file_name])
  @file_name = params[:file_name]
  @file_contents = File.read(file)
  
  erb :edit_file
end

post "/:file_name/delete" do
  file_path = File.join(data_path,params[:file_name])
  File.delete(file_path)
  session[:message] = "#{params[:file_name]} has been deleted"
  redirect "/"
end

post "/:file_name" do
  file = File.join(data_path,params[:file_name])
  File.write(file, params[:content])
  session[:message] = "#{params[:file_name]} has been updated."
  redirect "/"
end

get "/user/signin" do
  erb :signin
end

post "/user/authenticate" do
  if params[:user_name].downcase == 'admin' && params[:password] == 'secret'
    session[:user_name] = params[:user_name]
    session[:message] = "Welcome to  CMS"
    redirect "/"
  else
    session[:message] = "Invalid Credentials"
    erb :signin
  end
end

post "/user/signout" do
  session.delete(:user_name)
  session[:message] = "You have been signed out."
  redirect "/"
end


def file_exists?
  file = File.join(data_path,params[:file_name])
  files = Dir.glob(File.join(data_path,"*"))
  files.include?(file)
end

def retrieve_file_contents
  file = File.join(data_path,params[:file_name])
  @file_contents = File.read(file)  #beware of long files
end

def render_file
  if params[:file_name].reverse.start_with?('dm.')
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    markdown.render(@file_contents)
  elsif params[:file_name].reverse.start_with?('.txt')
    headers["Content-Type"] = "text/plain"
    
    @file_contents
  end
end
