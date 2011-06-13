require 'rubygems'
require 'net/http'
require 'uri'
require 'json'
require 'mongo'


class OmegleResponse
  
  attr_accessor :status_code, :message, :time
  
  def initialize response
    @time = Time.now
    @status_code = response.first[0]
    @message = response.first[1]
  end
  
end


class OmegleClient
  
  BASE_URI  = "http://bajor.omegle.com"
  attr_accessor :history
  def initialize
    @chat_id = nil
    @history = []
    @status = :disconnected
  end
  
  def should_poll?
    @status == :ready
  end
  
  def connect!
    url = URI.parse("#{BASE_URI}/start")
		id = Net::HTTP.get(url)
    @status = :ready
		@chat_id = id[1..6]
  end
  
  def poll
    if should_poll?
      begin
        eventraw = Net::HTTP.post_form(URI.parse("#{BASE_URI}/events"), {'id' => @chat_id})
	      create_response_from_json(JSON.parse(eventraw.body))
      rescue Timeout::Error
        create_response_from_json [['strangerDisconnected']]
      end
    end
  end
  
  def say(something)
    Net::HTTP.post_form(URI.parse("#{BASE_URI}/send"), {'id' => @chat_id, 'msg' => something})
  end
  
  def to_mongo
    {
      :omegle_id => @chat_id,
      :date => @history.last.time,
      :history => @history.map{|h| {:date => h.time, :status => h.status_code, :message => h.message}}
    }
  end
  
  protected
  
  def create_response_from_json(json)
    @history << OmegleResponse.new(json)
    if @history.last.status_code == 'strangerDisconnected'
      @status = :disconnected
    end
    @history.last
  end
  
end

db = Mongo::Connection.new.db("hope")
coll = db.collection("messages")



while(true)
  o = OmegleClient.new
  puts o.connect!
  o.poll.inspect
  o.say("I hope I don't fall in love with you.")
  while o.should_poll?
    puts o.poll.inspect
  end
  coll.insert(o.to_mongo) and puts "saving to mongo" unless o.history.select{|h| h.status_code == "gotMessage" }.empty?
end