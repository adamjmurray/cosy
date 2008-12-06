require File.dirname(__FILE__)+'/spec_helper'

SEQUENCE_COUNT_LIMIT = 1000

describe Cosy::Sequencer do
      
  describe 'Implicit Values' do
    
    it 'should use the default octave when the first octave is implicit' do
      for note_name in 'A'..'G' do
        render(note_name).should == [note(Pitch.new(PITCH_CLASS[note_name], DEFAULT_OCTAVE))]
      end
    end

    # TODO: it breaks backwards compatibility, but I'd rather have nearest be the default
    it 'should use the previous octave for implicit octaves by default' do
      render('C4 C D# Bb').should == pitches(60,60,63,70)
      render('C5 C D# Bb').should == pitches(72,72,75,82)
    end
    
    it 'should minimize the interval for implicit octaves when the octave_mode is :nearest' do
      render('#octave_mode:"nearest" C4 C D# Bb').should == pitches(60,60,63,58)
      render('#octave_mode:#nearest C5 C D# Bb').should == pitches(72,72,75,70)
    end
    
    it 'should ascend for implicit octaves when the interval is a tritone and octave_mode is :nearest' do
      render('#octave_mode:"nearest" C4 F# C4 Gb').should == pitches(60,66,60,66)
      render('#octave_mode:#nearest G4 C# G4 Db').should == pitches(67,73,67,73)
    end
    
    it 'should use the previous octave for implicit octaves when the octave_mode is :previous' do
      render('#octave_mode:"nearest" C4 Bb D# #octave_mode:"previous" Bb').should == pitches(60,58,63,70)
      render('#octave_mode:#nearest G4 C# #octave_mode:#previous G4 Db').should == pitches(67,73,67,61)
    end
    
    it 'should not persist the value selected for an implicit octave' do
      render('C4 (C B3)*2').should == pitches(60,60,59,48,59)
    end
    
  end # described Ruby support
  
  
  def renderer(input)
    AbstractRenderer.new({:input => input})
  end
  
  def render(input)
    if input.is_a? AbstractRenderer
      renderer = input
    else
      renderer = renderer(input)
    end
    events = []
    count = 0
    while event=renderer.next_event and count < SEQUENCE_COUNT_LIMIT
      events << event
      count += 1
    end
    if count == SEQUENCE_COUNT_LIMIT
      # infinite loop prevention
      fail "#{input} output more than #{SEQUENCE_COUNT_LIMIT}" 
    end
    return events
  end
  
  def note(pitches,duration=nil,velocity=nil)
    if pitches.respond_to? :value
      pitches = pitches.value
    elsif pitches.is_a? Array
      pitches.map!{ |pitch| pitch.value if pitch.respond_to? :value }
    end
    velocity ||= DEFAULT_VELOCITY
    duration ||= DEFAULT_DURATION
    NoteEvent.new(pitches,velocity,duration)
  end
  alias n note
  
  def pitches(*args)
    args.map{ |pitch| note(pitch) }
  end
  
end

