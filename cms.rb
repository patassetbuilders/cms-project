require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"
require "pry"
require "pry-byebug"

#blogg http://cms-project.blogspot.com.au/

root = File.expand_path("..", __FILE__) #"/Users/Pat/code/Launch-School/cms-project"

get "/" do
  @contents = Dir.glob(root + "/data/*").map do |path|
    File.basename(path)
  end 
  erb :index
end