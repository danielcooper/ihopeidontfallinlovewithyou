require 'sinatra'
require 'mongo'

get '/' do
  db = Mongo::Connection.new.db("hope")
  coll = db.collection("messages")
  @conversations = coll.find({}, {:sort => ['date', :desc]}).limit(5)
  erb :index
end

get '/conversations/:id' do |id|
  db = Mongo::Connection.new.db("hope")
  coll = db.collection("messages")
  @conversation = coll.find_one({'omegle_id' => id})
  erb :conversation
end