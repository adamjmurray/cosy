module Cosy

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

end