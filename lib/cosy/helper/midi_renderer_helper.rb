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
  alias orig_note_on note_on
  alias orig_note_off note_off

  def initialize(*params)
    orig_init(*params)
    @held_notes = Hash.new {|hash,key| hash[key]={} }
    at_exit do
      @held_notes.each do |channel,notes|
        notes.each do |note,velocity|
          orig_note_off(note, channel, velocity)
        end
      end
      close
    end
  end  

  def note_on( note, channel, velocity )
    orig_note_on( note, channel, velocity )
    @held_notes[channel][note] = velocity
  end

  def note_off( note, channel, velocity = 0 )
    orig_note_off( note, channel, velocity )
    @held_notes[channel].delete(note)
  end
end
