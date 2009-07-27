module Cosy
  
  module Event
        
    class Note
      attr_accessor :pitch, :velocity, :duration, :channel
      
      def initialize(pitch, velocity, duration, channel=nil)
        @pitch, @velocity, @duration, @channel = pitch.to_i, velocity.to_i, duration.to_i, channel
      end

      def eql?(other)
        self == other
      end

      def ==(other)
        other.is_a? NoteEvent and other.pitch==@pitch and other.velocity==@velocity and
        other.duration==@duration and other.channel==@channel
      end    

      def to_s
        inspect
      end
      
      def pvdc
        return pitch, velocity, duration, channel
      end

      def inspect
        s = '{pitch:' + @pitch.inspect
        s += ',velocity:' + @velocity.inspect
        s += ',duration:' + @duration.inspect
        s += ',channel:' + @channel.inspect if channel
        s += '}'
        return s
      end     
    end
    
    
    class ProgramChange
      attr_accessor :program_number, :channel
      def initialize(program_number, channel=nil)
        @program_number, @channel = program_number, channel
      end
    end
    
    
    class Rest
      attr_accessor :duration
      
      def initialize(duration)
        @duration = duration
      end
    end
    
    
    class ControlChange
      attr_accessor :controller_number, :value, :channel
    
      def initialize(controller_number, value, channel=nil)
        @controller_number, @value, @channel = controller_number, value, channel
      end
    end
    
    
    class PitchBend
      attr_accessor :amount, :channel
    
      def initialize(amount, channel=nil)
        @amount, @channel = amount, channel
      end
      
      def midi
        # assume range -1.0 to 1.0
        if @amount == -1.0
          0
        else
          # pitch bends go from 0 (lowest) to 16383 (highest) with 8192 in the center
          (@amount * 8191 + 8192).to_i 
        end
      end
    end
    
        
    class Tempo
      attr_accessor :bpm
      def initialize(bpm)
        @bpm = bpm
      end
    end
   
    
    class OscMessage
      attr_accessor :host, :port, :path, :args
      def initialize(host,port,path,*args)
        @host,@port,@path,@args = host,port,path,args
      end
      
      def to_s
        "osc://#{host}:#{port}#{path} #{args}"
      end
    end
  end
end