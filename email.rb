if not RUBY_VERSION =~ /1.9/
  abort "You need ruby version 1.9"
end
require './simpleswitch'
require './mailstore'
Thread.abort_on_exception = true
#TODO create config file for server values
db = Database.new
message = nil
socket = nil
modulus = db.modulus
response_callback = lambda do |msg|
  p "Got your message: #{msg["+body"]}"
  if msg.has_key? "+body"
    db.store(:from => msg["+from"], :message => msg["+body"], :time => Time.now, :user => msg["+end"])
    return
  elsif msg.has_key? "+getmail"
    p "modulus: #{modulus}"
    message.body = { "+callback" => db.mail(msg["+end"]), "+end" => msg["+from"] }
    message.send_message
  elsif msg.has_key? "+newhost"
    db.add_host(msg["+newhost"], modulus)
    message.body = db.tap(modulus)
    message.send_message
  end
end

after_connect = lambda do |this|
  p "My modulus: #{modulus.to_s.sha1}"
  this.message.body = db.tap(modulus)
  this.message.send_message
  socket = this
  message = this.message
end
  

switch = Switch.new(
          "response_callback"=>response_callback, 
          "host" => "nostat.us",
          "after_connect" => after_connect
          )
Thread.new do
  switch.start_udpserver
end
sleep 5000000
