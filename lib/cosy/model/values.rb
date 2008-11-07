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
    def initialize(pitch_class, accidental, octave, text_value)
      @pitch_class = pitch_class
      @accidental = accidental
      @octave = octave
      @text_value = text_value
      recalc_value
    end
    
    def has_octave?
      not @octave.nil?
    end
    
    def octave=(octave)
      @octave = octave
      recalc_value
    end
    
    private
    def recalc_value
      @value = pitch_class
      @value += accidental
      @value += octave if octave
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
