if not Hash.method_defined? :key then 
  class Hash
    alias key index # Ruby 1.8 compatibility for the Ruby 1.9 API
  end
end
  
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
      need_to_recalc_value = true
      case args.length
      when 1
        if args[0].is_a? Numeric
          self.value = args[0]
          need_to_recalc_value = false
        else
          self.pitch_class = args[0]
        end
      when 2
        self.pitch_class = args[0]
        self.octave = args[1]
      when 3
        self.pitch_class = args[0]
        self.accidental = args[1]
        self.octave = args[2]
      end
      @initialized = true
      recalc_value if need_to_recalc_value
    end
    
    def pitch_class=(pitch_class)
      if pitch_class.is_a? Numeric
        @pitch_class = pitch_class
      else
        @pitch_class = PITCH_CLASS[pitch_class.to_s.upcase]
        raise "Invalid pitch class: #{pitch_class}" if not @pitch_class
      end
      recalc_value
    end
    
    def accidental=(accidental)
      if accidental.nil?
        @accidental = 0
      elsif accidental.is_a? Numeric
        @accidental = accidental
      else
        accidental_value = 0
        accidental.each_byte do |byte|
          acc = ACCIDENTAL[byte.chr]
          raise "Invalid accidental: #{accidental}" if not acc           
          accidental_value += acc
        end
        @accidental = accidental_value
      end
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
      ival = val.to_i
      @pitch_class = ival % 12
      @accidental = val - ival
      case @pitch_class
      when 1,3,6,8,10
        @pitch_class -= 1
        @accidental += 1
      end
      @octave = ival/12 - $OCTAVE_OFFSET
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
  
    #########  
    private
    
    def recalc_value
      if @initialized
        @value = @pitch_class
        @value += @accidental if @accidental
        @value += 12*(@octave+$OCTAVE_OFFSET) if @octave
        recalc_text_value
      end
    end
    
    def recalc_text_value
      @text_value = PITCH_CLASS.key(@pitch_class)
      if @text_value
        # TODO: this doesn't handle fractional pitch values properly
        @accidental.to_i.abs.times{|i| @text_value += if @accidental > 0 then '#' else 'b' end} if @accidental
        @text_value += @octave.to_s if @octave
      # else ??? 
      # this case can happen with fractional pitches (microtones), need to think more about how this should work
      end
    end
  end
  
  
  class Interval < Value
    attr_accessor :quality, :degree, :text_value
    
    def initialize(*args)
      need_to_recalc_value = true
      case args.length
      when 1
        @text_value = args[0]
        if @text_value.is_a? Numeric
          self.value = @text_value
          @text_value = @text_value.to_s
          need_to_recalc_value = false
        elsif @text_value =~ /(-?)([A-Za-z]*)(\d*)/
          sign = $1
          self.quality = $2
          @degree = $3.to_i
          @degree *= -1 if sign=='-'
        else
          raise "Bad interval format: #{text_value}"
        end
      when 2
        self.quality = args[0]
        @degree = args[1].to_i
      else
        raise "Bad arguments #{args.inspect}"
      end
      @initialized = true
      recalc_value if need_to_recalc_value
    end
    
    def quality=(quality)
      if quality.is_a? String
        quality = quality.downcase unless quality.length == 1
        @quality = INTERVAL_QUALITY[quality]
      else
        @quality = quality
      end
      if not INTERVAL_QUALITY.has_value? @quality
        raise "Unknown quality #{@quality}"
      end
      recalc_value
    end
    
    def degree=(degree)
      @degree = degree.to_i
      recalc_value
    end
    
    def value=(value)
      @value = value
      negative = value < 0
      semitones = value.abs
      @quality,@degree = INTERVAL_VALUES[semitones % 12]
      @degree += 8*semitones/12
    end
    
    # TODO text_value
    
    private
    def recalc_value
      if @initialized
        if @degrees == 0
          @value = deg = 0
        else
          deg = @degree.abs % 7
          @value = INTERVAL_DEGREE[deg]
        end
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
  end
  
  
  class Velocity < Value
    def initialize(velocity,text_value=nil)
      if velocity.is_a? String or velocity.is_a? Symbol
        vel = INTENSITY[velocity.to_s.downcase]
        raise "Invalid velocity: #{velocity}" if not vel
        velocity = vel
      end
      super(velocity,text_value)
    end
  end
  
  
  class Duration < Value
    
    attr_accessor :base_duration, :multiplier, :modifier
    
    def initialize(*args)
      case args.length
      when 1
        self.base_duration = args[0]
      when 2
        self.multiplier = args[0]
        self.base_duration = args[1]  
      when 3
        self.multiplier = args[0]
        self.base_duration = args[1]
        self.modifier = args[2]
      end
      @initialized = true
      recalc_value
    end
    
    def base_duration=(value)
      if value.is_a? Numeric      
        @base_duration = value
      else
        value = DURATION[value.downcase]
        raise "Invalid duration #{value}" if not value
        @base_duration = value
      end
      recalc_value
    end
    
    def modifier=(value)
      if value.nil?
        @modifier = 1
      else
        modifier_value = 1
        value.each_byte do |byte|
          mod = DURATION_MODIFIER[byte.chr]
          raise "Invalid duration modifier: #{value}" if not mod
          modifier_value *= mod
        end
        @modifier = modifier_value
      end
      recalc_value
    end
    
    def multiplier=(value)
      if value.nil?
        @multiplier = 1
      else
        @multiplier = value
      end
      recalc_value
    end
    
    #########
    private
    
    def recalc_value
      if @initialized
        @value = @base_duration
        @value *= @multiplier if @multiplier
        @value *= @modifier if @modifier
      end
    end
    
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
      s += ',' + @velocity.inspect + " (#{@velocity.class}) " if @velocity
      s += ',' + @duration.inspect if @duration
      s += ">"
      return s
    end
  end


  class OscAddress
    attr_accessor :host, :port, :path
    def initialize(host,port,path)
      @host,@port,@path = host,port,path
      @host = nil if @host == ''
      @port = nil if @port == ''
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
