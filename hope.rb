require 'sinatra'
require 'mongo'

get '/' do
  db = Mongo::Connection.new.db("hope")
  coll = db.collection("messages")
  @conversations = coll.find({}, {:sort => ['date', :desc]}).limit(5)
  
  erb :index
end