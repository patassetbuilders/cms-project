require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"
require "pry"
require "pry-byebug"

get "/" do
  erb :home
end
