require "socket"

module SMQueue
  class IRCAdapter < Adapter
    class Configuration < AdapterConfiguration
      has :server, :kind => String, :default => "" do
        doc <<-EDOC
          The server that runs the channel you want to connect to.
        EDOC
      end
      has :port, :kind => Integer, :default => 6667 do
        doc <<-EDOC
          The port that your IRC server is running on.
          
          The default port is 6667.
        EDOC
      end
      has :nick, :kind => String, :default => "" do
        doc <<-EDOC
          The IRC nick your adapter should run as.
        EDOC
      end
      has :channel, :kind => String, :default => "" do
        doc <<-EDOC
          The channel that your IRC adapter is running on.
        EDOC
      end
    end
    
    has :connection, :default => nil
    has :connected, :default => false

    def initialize(*args, &block)
      super
    end
    
    def connect()
      # Connect to the IRC server
      @irc = TCPSocket.open(configuration.server, configuration.port)
      say "USER blah blah blah :blah blah"
      say "NICK #{configuration.nick}"
      say "JOIN #{configuration.channel}"
      
      while !connected
        read_from_server do |msg|
          if (msg == :connected)
            self.connected = true
            # FIXME: how to read and write at the same time?
            Thread.new do
              while true
                read_from_server
              end
            end
            return
          end
        end
      end
    end
    
    def get(&block)
      m = nil
      connect if !connected
      while true
        ready = select([@irc], nil, nil, nil)
        next if !ready
        for s in ready[0]
          if s == @irc then
            return if @irc.eof
            s = @irc.gets
            msg = handle_server_input(s)
            yield(msg) unless msg.nil?
          end
        end
      end
    end
    
    def put(msg)
      connect if !connected
      say("PRIVMSG #{configuration.channel} : #{msg}")
    end
    
    protected
    
    def say(s)
      # Send a message to the irc server and print it to the screen
      @irc.send "#{s}\n", 0 
    end
    
    def read_from_server(&block)
      while true
        ready = select([@irc], nil, nil, nil)
        next if !ready
        for s in ready[0]
          if s == @irc then
            return if @irc.eof
            s = @irc.gets
            msg = handle_server_input(s)
            yield(msg) unless msg.nil?
          end
        end
      end
    end
    
    def handle_server_input(s)
      msg = nil
      
      # This isn't at all efficient, but it shows what we can do with Ruby
      # (Dave Thomas calls this construct "a multiway if on steroids")
      case s.strip
        when /^PING :(.+)$/i
          say "PONG :#{$1}"
        when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s.+\s:[\001]PING (.+)[\001]$/i
          say "NOTICE #{$1} :\001PING #{$4}\001"
        when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s.+\s:[\001]VERSION[\001]$/i
          say "NOTICE #{$1} :\001VERSION Ruby-irc v0.042\001"
        when /^:(.+?)!(.+?)@(.+?)\sJOIN\s:(.+)$/i
          msg = :connected if ($4 == configuration.channel)
        when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s(.+)\s:(.+)$/i
          sender, recepient, body = $1, $4, $5
          recepient, body = $1, $2 if (body =~ /^(#{configuration.nick}):(.+)/)
          
          if (recepient == configuration.nick)
            msg = SMQueue::Message.new(
              :headers => {
                :sender => sender,
             },
               :body => body
             )
          end
        else
          # puts s
      end
      msg
    end
  end
end
