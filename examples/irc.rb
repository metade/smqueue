require 'lib/smqueue'
require 'pp'

require 'socksify'
TCPSocket::socks_server = "socks-gw.reith.bbc.co.uk"
TCPSocket::socks_port = 1085

script_path = File.dirname(__FILE__)
configuration = YAML::load(File.read(File.join(script_path, "config", "example_config.yml")))

Thread.abort_on_exception = true

input_queue = SMQueue.new(:configuration => configuration[:readline])
output_queue = SMQueue.new(:configuration => configuration[:irc_output])

output_queue.connect

input_queue.get do |msg|
  output_queue.put msg.body
end
