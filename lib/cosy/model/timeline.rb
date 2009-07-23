
module Cosy
  
  class Timeline
    
    def initialize(events=nil)
      @events = events || Hash.new {|hash,key| hash[key] = [] }
    end
    
    def []=(time,event)
      fail "bad time type: #{time.class}" if not time.is_a? Numeric
      if event 
        @events[time] = [event] 
      else 
        @events.delete(time)
      end
    end
    
    def [](time)
      fail "bad time type: #{time.class}" if not time.is_a? Numeric
      @events[time]
    end
    
    def times
      @events.keys.sort
    end
    
    def each_time
      times.each do |time|
        events = @events[time]
        yield time,events
      end
    end
    
    def each_event
      times.each do |time|
        events = @events[time]
        events.each do |event|
          yield time,event
        end
      end
    end
      
    def to_s
      s = nil
      each_time do |time,events|
        if s then s += "\n" else s = '' end
        s += "#{time} => " + events.inspect
      end
      return s
    end   
    
    def method_missing(name, *args, &block) 
      @events.__send__(name, *args, &block)
    end 

  end
  
end