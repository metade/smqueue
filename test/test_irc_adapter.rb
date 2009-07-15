require File.dirname(__FILE__) + '/helper'

class TestRStompConnection < Test::Unit::TestCase

  # Tests handle_server_input method 
  test "handle_server_input ignores messages not sent to the queue" do
    stub_connection_calls_to_queue
    adapter = SMQueue.new(:configuration => YAML.load(configuration))
    adapter.connect
    
    assert_nil adapter.send(:handle_server_input, 
      ':verne.freenode.net 001 nick :Welcome to the freenode IRC Network nick')
    assert_nil adapter.send(:handle_server_input, 
      ":metade!n=metade@gatea.mh.bbc.co.uk PRIVMSG #channel :foo\r\n")
  end
  
  test "handle_server_input accepts messages that are sent to the queue" do
    message = SMQueue::Message.new(
      :headers => {
        :sender => 'metade', 
      },
      :body => 'have a message'
    )
    
    stub_connection_calls_to_queue
    adapter = SMQueue.new(:configuration => YAML.load(configuration))
    adapter.connect
    
    assert_equal message, adapter.send(:handle_server_input, 
      ":metade!n=metade@gatea.mh.bbc.co.uk PRIVMSG #channel :nick:have a message\r\n")
    assert_equal message, adapter.send(:handle_server_input, 
        ":metade!n=metade@gatea.mh.bbc.co.uk PRIVMSG nick :have a message\r\n")
  end
  
  
  def stub_connection_calls_to_queue
    TCPSocket.stubs(:open).returns stub_everything('TCPSocket')
  end
  
private

  def configuration
    yaml = %[
      :adapter: SMQueue::IRCAdapter
      :channel: channel
      :nick: nick
    ]
  end
end
