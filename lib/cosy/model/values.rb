module Cosy

  class Chord < Array
  end
  
  
  class Chain < Array
  end


  class Value
    attr_accessor :value
    
    def initialize(value, text_value=nil)
      @value = value
      @text_value = text_value
      @text_value ||= @value.to_s if @value
    end
    
    def inspect
      "#@text_value (#{self.class}=#@value)"
    end
    
    def eql?(other)
      if other.respond_to? :value
        return @value.eql?(other.value)
      else
        return @value.eql?(other)
      end
    end
    
    def ==(other) 
      if other.is_a? Value
        return @value == other.value
      else
        return @value == other
      end
    end
    
    def hash
      @value.hash
    end
  end
  
  
  class Pitch < Value
    
    attr_reader :pitch_class, :accidental, :octave
    
    def initialize(*args)
      case args.length
      when 1
        self.value = args[0]
      when 3
        @pitch_class = args[0]
        @accidental = args[1]
        @octave = args[2]
        recalc_value
      end
    end
    
    def pitch_class=(pitch_class)
      @pitch_class = pitch_class
      recalc_value
    end
    
    def accidental=(accidental)
      @accidental = accidental
      recalc_value
    end
    
    def has_octave?
      not @octave.nil?
    end
    
    def octave=(octave)
      @octave = octave
      recalc_value
    end
    
    def value=(val)
      @value = val
      @pitch_class = val % 12
      case @pitch_class
      when 1,3,6,8,10
        @pitch_class -= 1
        @accidental = 1
      end
      @octave = val/12 - $OCTAVE_OFFSET
      recalc_text_value
    end
    
    def +(other)
      if other.respond_to? :value
        return Pitch.new(@value + other.value)
      else
        # TODO: better type checking?
        return Pitch.new(@value + other)
      end
    end
    
    def to_s
      @text_value
    end
    
    def inspect
      str = "#@text_value (#{self.class}={value=#@value, pitch_class=#@pitch_class"
      str += ", accidental=#@accidental" if @accidental
      str += ", octave=#@octave" if @octave
      str += ")"
      return str
    end
    
    private
    def recalc_value
      @value = @pitch_class
      @value += @accidental if @accidental
      @value += 12*(@octave+$OCTAVE_OFFSET) if @octave
      recalc_text_value
    end
    
    def recalc_text_value
      @text_value = PITCH_CLASS.index(@pitch_class)
      if @text_value
        @accidental.abs.times{|i| @text_value += if @accidental > 0 then '#' else 'b' end} if @accidental
        @text_value += @octave.to_s if @octave

      # else ??? 
      # this case can happen with fractional pitches (microtones), need to think more about how this should work
      end
    end
  end
  
  
  class Interval < Value
    
    attr_accessor :quality, :degree, :text_value
    
    def initialize(*args)
      case args.length
      when 1
        @text_value = args[0]
        if @text_value =~ /(-?)([A-Za-z]*)(\d*)/
          sign = $1
          qual = $2
          qual = qual.downcase unless qual.length == 1
          @quality = INTERVAL_QUALITY[qual]
          @degree = $3.to_i
          @degree *= -1 if sign=='-'
        else
          raise "Bad interval format: #{text_value}"
        end
      when 2
        @quality = args[0]
        @degree = args[1].to_i
      else
        raise "Bad arguments #{args.inspect}"
      end
      if not INTERVAL_QUALITY.has_value? @quality
        raise "Unknown quality #{if not qual.nil? then qual else @quality end}"
      end
      recalc_value
    end
    
    def quality=(quality)
      @quality = quality
      if not INTERVAL_QUALITY.has_value? @quality
        raise "Unknown quality #{@quality}"
      end
      recalc_value
    end
    
    def degree=(degree)
      @degree = degree.to_i
      recalc_value
    end
    
    # TODO text_value
    
    private
    def recalc_value
      deg = @degree.abs % 7
      @value = INTERVAL_DEGREE[deg]
      # now value is set to a perfect/major interval, so
      # adjust if needed for the other possible interval qualities
      case @quality
      when :minor then @value -= 1
      when :diminished then 
        case deg
        when 1,4,5 # perfect intervals diminish by one semitone
          @value -= 1
        else
          @value -= 2
        end
      when :augmented then @value += 1
      end
      @value += 12 if @value < 0
      @value *= -1 if @degree < 0
    end
  end
  
  
  class Velocity < Value
  end
  
  
  class Duration < Value
  end
  
  
  class Tempo < Value
  end
  
  
  class Program < Value
  end


  class Label < Value
  end
  
  
  class NoteEvent
    attr_accessor :pitches, :velocity, :duration
    def initialize(pitches, velocity, duration)
      if pitches.is_a? Array
        @pitches = pitches
      else 
        @pitches = [pitches] 
      end
      @velocity, @duration = velocity, duration
    end

    def eql?(other)
      self == other
    end

    def ==(other)
      other.is_a? NoteEvent and other.pitches==@pitches and 
      other.velocity==@velocity and other.duration==@duration
    end

    def to_s
      inspect
    end

    def inspect
      s = "Note<"
      s += @pitches.inspect
      s += ',' + @velocity.inspect if @velocity
      s += ',' + @duration.inspect if @duration
      s += ">"
      return s
    end
  end


  # Allows a Cosy Value object to be equal to the underlying @value it wraps
  module ValueEquality
    alias orig_ee ==
    alias orig_eql? eql? 
    def ==(other)
      if other.is_a? Cosy::Value
        return orig_ee(other.value)
      else
        return orig_ee(other)
      end
    end
    def eql?(other)
      if other.is_a? Cosy::Value
        return orig_eql?(other.value)
      else
        return orig_eql?(other)
      end
    end
  end
end



class Fixnum
  include Cosy::ValueEquality
  # now C4==60, etc
end
