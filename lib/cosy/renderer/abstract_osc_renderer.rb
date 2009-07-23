require 'osc'

module Cosy

  class AbstractOscRenderer < AbstractRenderer

    def initialize(options={})
      super
      @host   = options.fetch :host, 'localhost'
      @port   = options[:port]
      @client = options[:client]
      
      # TODO: during initialization, scan for all osc host/port combos
      # in the timeline and open all connections
    end
    
    
    ##########
    private
    
    def osc_host(hostname)
      @host = hostname
    end
    
    def osc_port(port)
      @port = port
      puts "starting client for #@host:#{port}" if $DEBUG
      @client = OSC::SimpleClient.new(@host, port)
    end
    
    def osc(address, args) 
      if @client
        msg = OSC::Message.new(address, nil, *args)
        begin
          @client.send(msg) 
        rescue => exception
          STDERR.puts "OSC to #@host:#@port failed to send: #{address} #{args}"
          STDERR.puts "#{exception.message}"            
        end
      else
        STDERR.puts 'OSC client not started' 
      end
    end
    
  end
  
end
