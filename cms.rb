require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"
require "pry"
require "pry-byebug"

#blogg http://cms-project.blogspot.com.au/


configure do
  enable :sessions
  set :session_secret, 'cmc-secret'
  #set :erb, :escape_html => true
end

root = File.expand_path("..", __FILE__) #"/Users/Pat/code/Launch-School/cms-project"

get "/" do
  cms_contents
  erb :index
end

get "/read_file/:file_name" do
  if cms_contents.include? params[:file_name]
    file = root + "/data/" + params[:file_name]
    @file_contents = File.read(file)  #beware of long files
    erb :show_file
  else
    session[:message] = "#{params[:file_name]} does not exist."
    redirect "/"
  end
end

def cms_contents
  root = File.expand_path("..", __FILE__)
  @contents = Dir.glob(root + "/data/*").map do |path|
    File.basename(path)
  end 
end
