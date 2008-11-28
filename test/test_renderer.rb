require 'test/unit'
$:.unshift File.dirname(__FILE__)+'/../lib'
require 'cosy'

class TestRenderer < Test::Unit::TestCase
  include Cosy
  require 'set'
  SEQUENCE_COUNT_LIMIT = 1000
  
  # define constants for intensities: P, PP, PPP, MP, etc
  INTENSITY.each do |key,value|
    const_set(key.upcase, value) if key.length <= 3
  end
   
  def assert_sequence(expected, input)
    renderer = AbstractRenderer.new({:input => input})
    actual = []
    count = 0
    while event=renderer.next_event and count < SEQUENCE_COUNT_LIMIT
      actual << event
      count += 1
    end
    if count == SEQUENCE_COUNT_LIMIT
      fail "#{input} output more than #{SEQUENCE_COUNT_LIMIT}" 
    end
    assert_equal(expected, actual)
  end
  
  def note(pitches,duration=nil,velocity=nil)
    velocity ||= RendererDefaults.DEFAULT_VELOCITY
    duration ||= RendererDefaults.DEFAULT_DURATION
    NoteEvent.new(pitches,velocity,duration)
  end
  alias n note
  
  def test_use_previous_octave
    assert_sequence [note(60),note(60),note(62),note(71)], 'C C D B'
    assert_sequence [note(72),note(72),note(74),note(83)], 'C5 C D B'
  end
  
  def test_pitches
    assert_sequence [n(60),n(62),n(63),n(56),n(55),n(48),n(36)], 'C4 D4 Eb4 g#3 g3 c3 c2'
  end
  
  def test_rhythm
    def r(dur)
      n(60,dur)
    end
    assert_sequence [
      r(1920),r(960),r(320.0),r(320.0),r(320.0),r(720.0),r(240),r(720.0),r(240),
      r(960),r(60),r(60),r(60),r(60),r(60),r(60),r(60),r(60),
      r(30),r(30),r(30),r(30),r(30),r(30),r(30),r(30),
      r(30),r(30),r(30),r(30),r(30),r(30),r(30),r(30),r(1920)
    ],
    'C4:w h qt qt qt q. ei q. ei 8s r r r r r r r r x x x x x x x x x x x x x x x x w'
  end
  
  def test_velocity
    def v(vel)
      n(60,nil,vel)
    end
    assert_sequence [v(PPP),v(PP),v(P),v(MP),v(MF),v(FO),v(FF),v(FFF)], 'C4:ppp pp p mp mf fo ff fff'
  end
  
  def test_notes
    assert_sequence [
      n(60,240,MF),n(62,240,MF),n(64,480,MP),n(65,240,MP),n(67,960,MP),
      n(69,240,P),n(65,240,P),n(64,240,MP),n(62,720.0,MF),n(60,1920,FF)
    ], 
    'C4:ei:mf  D4  E4:q:mp  F4:ei  G4:h A4:ei:p  F4  E4:mp  D4:q.:mf  C4:w:ff'
  end
  
  def test_chords
    assert_sequence [
      n([48,55,63,72],960),n([48,56,63,72],960),n([49,56,65,73],960),
      n([55,62,65,71],960),n([36,48,55,60,67,72],3840)
    ], 
    '[C3 G3 Eb4 C5]:h [C3 Ab3 Eb4 C5] [Db3 Ab3 F4 Db5] [G3 D4 F4 B4] [C2 C3 G3 C4 G4 C5]:2w'
  end
  
  def test_rests
    assert_sequence [
      n(64,240),n(62,240),n(60,240),n(60,-240),n(64,120),n(64,-360),
      n(65,240),n(67,240),n(67,-480),n(59,480),n(59,-480),n(52,1920)],
    'E4:ei D4 C4 -ei E4:s -ei. F4:ei G4 -q B3 -q E3:w'
  end
  
  def test_reptitions
    assert_sequence [
      n(67,240),n(65,240),n(67,240),n(65,240),n(67,240),n(65,240),n(64,240),n(62,240),
      n(67,240),n(65,240),n(67,240),n(65,240),n(67,240),n(65,240),n(64,240),n(62,240),
      n(60,240),n(60,240),n(60,240),n(60,240),n(60,240)
      ], 
      '((G4:ei F4)*3 E4 D4)*2 C4*5'
  end
  
  def test_count_limit
    assert_sequence [
      n(60),n(62),n(64),n(60),n(62),n(67),n(65),n(64),n(67),n(59),n(62),n(59),n(62),n(57),n(59),n(60)
    ], 
    '(C4 D4 E4)&5 (G4 F4 E4)&4 ((B3 D4)*2 A3)&6 C4'
  end
  
  def test_choice
    renderer = AbstractRenderer.new({:input => '( (C4 | E4 | G4)  (C5 | E5 | G5) )*8'})
    actual = []
    count = 0
    while event=renderer.next_event and count < SEQUENCE_COUNT_LIMIT
      octave = count%2 * 12
      case event
      when n(60+octave),n(64+octave),n(67+octave) then ; # keep going
      else flunk "event #{event.inspect} was not one of the expected values"
      end
      count += 1
    end
    if count == SEQUENCE_COUNT_LIMIT
      fail "#{input} output more than #{SEQUENCE_COUNT_LIMIT}" 
    end
  end
  
  def test_variable
    assert_sequence [
      n(67,120),n(69,120),n(70,120),n(71,120),
      n([48,55,64,72],960),n([48,55,63,72],960),n(36,1920)
    ],
    ' $C_MAJOR     = [C3 G3 E4 C5];
      $C_MINOR     = [C3 G3 Eb4 C5];
      $LEAD_IN     = G4 A4 Bb4 B4;
      $FINAL_PITCH = C2;

      $LEAD_IN:s $C_MAJOR:h $C_MINOR:h $FINAL_PITCH:w'
  end
  
  def test_chaining
    assert_sequence [
      n(67,720,P),n(65,240,MF),n(64,720,FF),n(62,240,P),
      n(67,720,MF),n(65,240,FF),n(64,720,P),n(62,240,MF),
      n(67,720,FF),n(65,240,P),n(64,720,MF),n(62,240,FF),
      n(67,720,P),n(65,240,MF),n(64,720,FF),n(62,240,P),
      n(60,720,MF)
    ],
    '((G4 F4 E4 D4)*4 C4):(q. ei):(p mf ff)'
  end
  
  def test_repeated_numeric_pitches
    assert_sequence [n(60)]*4, 'y60*4'
  end
  
  def test_intervals
    assert_sequence [n(60),n(62),n(63)], 'C M2 m2'
  end
  
end
