require 'midiator'

module Cosy
  
  class MidiInterface
    @drivers = {}

    def self.get(driver)
      midi = @drivers[driver]
      if not midi
        midi = MIDIator::Interface.new
        if driver
          midi.use(driver)
        else
          midi.autodetect_driver
        end
        @drivers[driver] = midi
      end
      return midi
    end

    private     
    def initialize 
    end
  end
  
end

# Make MIDIator cleanup at program termination:
class MIDIator::Driver
  
  alias orig_init initialize
  
  def initialize(*params)
    orig_init(*params)
    at_exit do
      for channel in 0..15 do
        for note in 0..127 do
          note_off(note, channel, 100)
        end
      end
    end
  end
    
end
