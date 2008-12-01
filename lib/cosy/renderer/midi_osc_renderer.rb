require 'osc'
include  OSC

module Cosy

  class MidiOscRenderer < MidiRenderer

    def initialize(options)
      super(options)
      @host = 'localhost'
    end

    ##########
    private
    
    def osc_host(hostname)
      @host = hostname
    end
    
    def osc_port(port)
      puts "starting client for #@host:#{port}" if $DEBUG and not @client
      @client = SimpleClient.new(@host, port) if not @client
    end
    
    def osc(address, args) 
      if @client
        msg = Message.new(address, nil, *args)
        add_event { @client.send(msg) } 
      else
        STDERR.puts 'OSC client not started'
      end
    end
    
  end
  
end
