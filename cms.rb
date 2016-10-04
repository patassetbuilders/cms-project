require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"
require "pry"
require "pry-byebug"

#blog https://www.blogger.com/blogger.g?blogID=3808378357003388534#editor/target=page;pageID=7961129763412562467

root = File.expand_path("..", __FILE__) #"/Users/Pat/code/Launch-School/cms-project"

get "/" do
  @contents = Dir.glob(root + "/data/*"),map do |path|
    File.basename(path)
  end 
  #using the 'entries' method will also show hidden files
  # @contents = Dir.entries("data")
  erb :index
end