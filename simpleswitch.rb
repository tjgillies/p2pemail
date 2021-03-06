require 'socket'
require 'digest/sha1'
require 'json'
require 'yaml'

#Thread.abort_on_exception = true
#TODO config file
class String
  def sha1
    Digest::SHA1.hexdigest(self)
  end
end

class UDPMessage
  attr_accessor :hostname, :port, :body, :line, :me, :br, :to
  def initialize(socket)
    @socket = socket
    @br = 0
  end
  def send_message
    body = { "_to" => self.to, "_line" => self.line, "_br" => self.br }
    self.body = self.body.merge(body.select{|k,v| !v.nil?})
    p self.body.to_json
    @socket.send self.body.to_json, 0, self.hostname, self.port
  end
end


class Switch
  attr_accessor :modulus, :to, :line, :br, :message
  def initialize(options={})
    host = options["host"] || "telehash.org"
    port = options["port"] || 42424
    @server =  Socket.getaddrinfo(host,'http').first[2]
    @port = port
    @to = "#{@server}:#{@port}"
    @response_callback = options["response_callback"] || lambda {|x|}
    @after_connect = options["after_connect"] || lambda {|x|}
  end
  
  def ping_loop
    loop do
      sleep 30
      p "Sending ping, I am: #{@message.me}"
      @message.body = {"_to"=>@to, "_line" => @message.line, "_br"=> @message.br}
      @message.send_message
    end
  end
  
  def receive_loop
    counter = 1
    loop do
      p "waiting for message"
      response, addr = @socket.recvfrom(50000000)
      @message.br += response.size
      response_json = JSON.parse(response)
      p response_json
      line = nil
      @response = response_json
      if response_json.has_key?("_ring")
        p "adding ring"
        line = response_json["_ring"]
        @message.me = response_json["_to"]
        @message.line = line
        p "line added to message"
        @after_connect.call(self)
        p "sucessfully called after_connect"
        Thread.new do
          ping_loop
        end if counter == 1
        counter += 1
      elsif not response_json.has_key?(".tap")
        @response_callback.call(response_json)
      end
      p "end of loop"
    end
  end
  


  def start_udpserver
    p "Starting server"
    @socket = UDPSocket.new
    p "binding server"
    p @socket.bind("0.0.0.0",0)
    @message = UDPMessage.new(@socket)
    @message.hostname = @server
    @message.port = @port
    @message.body = {"+end"=>"38666817e1b38470644e004b9356c1622368fa57"}
    p "sending message"
    @message.send_message
    Thread.new do
      receive_loop
    end
    rescue => e
      p e
      puts e.backtrace

  end
end
