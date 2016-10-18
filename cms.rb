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

root = File.expand_path("..", __FILE__) #"/Users/Pat/code/Launch-School/cms-project"

get "/" do
  cms_contents
  erb :index
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
  file_path = root + "/data/" + params[:file_name]
  @file_name = params[:file_name]
  @content = File.read(file_path)
  
  erb :edit_file
end


def cms_contents
  root = File.expand_path("..", __FILE__)
  @contents = Dir.glob(root + "/data/*").map do |path|
    File.basename(path)
  end 
end

def file_exists?
  cms_contents.include? params[:file_name]
end

def retrieve_file_contents
  root = File.expand_path("..", __FILE__) #"/Users/Pat/code/Launch-School/cms-project"
  file_path = root + "/data/" + params[:file_name]
  @file_contents = File.read(file_path)  #beware of long files
end

def render_file
  if params[:file_name].reverse.start_with?('dm.')
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    markdown.render(@file_contents)
  elsif params[:file_name].reverse.start_with?('.txt')
    @file_contents
  end
end
