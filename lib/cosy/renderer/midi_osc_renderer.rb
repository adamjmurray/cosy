require 'osc'

module Cosy

  class MidiOscRenderer < MidiRenderer

    def initialize(options)
      super(options)
      @host   = options[:host] || 'localhost'
      @port   = options[:port]
      @client = options[:client]
    end
    
    
    ##########
    private
    
    def osc_host(hostname)
      @host = hostname
    end
    
    def osc_port(port)
      @port = port
      puts "starting client for #@host:#{port}" if $COSY_DEBUG
      @client = OSC::SimpleClient.new(@host, port)
    end
    
    def osc(address, args) 
      if @client
        msg = OSC::Message.new(address, nil, *args)
        add_event do
          begin
            @client.send(msg) 
          rescue => exception
            STDERR.puts "OSC to #@host:#@port failed to send: #{address} #{args}"
            STDERR.puts "#{exception.message}"            
          end
        end
      else
        STDERR.puts 'OSC client not started'
      end
    end
    
    def clone_state(input)
      super(input).merge({
        :host => @host,
        :port => @port,
        :client => @client
      })
    end
    
  end
  
end
