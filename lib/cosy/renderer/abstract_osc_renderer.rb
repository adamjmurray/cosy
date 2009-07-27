require 'osc'

module Cosy
  
  # TODO: rather than use this artificially imposed class hierarchy
  # it would be cleaner to use the "Chain of Responsibility" pattern
  # and make this one handler that can be chained up to handel events

  class AbstractOscRenderer < AbstractRenderer

    def initialize(options={})
      super
      @clients = {}
      if @timeline
        @timeline.find_all{|event| event.is_a? Event::OscMessage}.each do |osc_message|
          # Open all the connections we'll need now
          get_client osc_message
        end
      end
    end
    
    
    ##########
    private
    
    def get_client(osc_message) 
      host, port = osc_message.host, osc_message.port
      client = @clients[[host,port]]
      if not client
        client = OSC::SimpleClient.new(host,port)
        @clients[[host,port]] = client
      end
      return client
    end
    
    def osc(osc_message)
      client = get_client osc_message 
      msg = OSC::Message.new(osc_message.path, nil, *osc_message.args)
      begin
        client.send(msg) 
      rescue => exception
        STDERR.puts "OSC message failed to send: #{osc_message}"
        STDERR.puts "#{exception.message}"            
      end
    end
    
  end
  
end
