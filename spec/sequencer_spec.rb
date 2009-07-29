require File.dirname(__FILE__)+'/spec_helper'

describe Cosy::Sequencer do

  def sequence(input)
    sequencer = Sequencer.new({:input => input})
    events = []
    count = 0
    while event=sequencer.next_event and count < SEQUENCE_COUNT_LIMIT
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
    velocity ||= DEFAULT_VELOCITY
    duration ||= DEFAULT_DURATION
    NoteEvent.new(pitches,velocity,duration)
  end
  alias n note

  def pitches(*args)
    args.map{ |pitch| note(pitch) }
  end

  def r(dur)
    n(60,dur)
  end

  def v(vel)
    n(60,nil,vel)
  end


  it 'should have infinite loop prevention in this spec' do
    lambda{ sequence("1*#{SEQUENCE_COUNT_LIMIT+1}") }.should raise_error(RuntimeError)
  end

  it 'needs to have test cases that verify the timeline datastructure'

  describe 'Note Sequencing' do
    it 'should sequence pitches' do
      sequence('C4 D4 Eb4 g#3 g3 c3 c2').should == [n(60),n(62),n(63),n(56),n(55),n(48),n(36)]
    end

    it 'should sequence rhythms' do
      input = 'C4:w h qt qt qt q. ei q. ei 8s r r r r r r r r x x x x x x x x x x x x x x x x w'
      expected = [
        r(W),r(H),r(Q*2/3),r(Q*2/3),r(Q*2/3),r(Q*1.5),r(EI),r(Q*1.5),r(EI),
        r(8*S),r(R),r(R),r(R),r(R),r(R),r(R),r(R),r(R),
        r(X),r(X),r(X),r(X),r(X),r(X),r(X),r(X),
        r(X),r(X),r(X),r(X),r(X),r(X),r(X),r(X),r(W)
      ]
      sequence(input).should == expected
    end

    it 'should sequence velocities' do
      expected = [v(PPP),v(PP),v(P),v(MP),v(MF),v(FO),v(FF),v(FFF)]
      sequence('C4:ppp pp p mp mf fo ff fff').should == expected
    end

    it 'should sequence notes' do
      expected = [
        n(60,EI,MF),n(62,EI,MF),n(64,Q,MP),n(65,EI,MP),n(67,H,MP),
        n(69,EI,P),n(65,EI,P),n(64,EI,MP),n(62,Q*1.5,MF),n(60,W,FF)
      ]
      input = 'C4:ei:mf  D4  E4:q:mp  F4:ei  G4:h A4:ei:p  F4  E4:mp  D4:q.:mf  C4:w:ff'
      sequence(input).should == expected
    end

    it 'should sequence chords' do
      expected = [
        n([48,55,63,72],H),n([48,56,63,72],H),n([49,56,65,73],H),
        n([55,62,65,71],H),n([36,48,55,60,67,72],2*W)
      ]
      input = '[C3 G3 Eb4 C5]:h [C3 Ab3 Eb4 C5] [Db3 Ab3 F4 Db5] [G3 D4 F4 B4] [C2 C3 G3 C4 G4 C5]:2w'
      sequence(input).should == expected
    end

    it 'should sequence rests' do
      expected = [
        n(64,EI),n(62,EI),n(60,EI),n(60,-EI),n(64,S),n(64,-EI*1.5),
        n(65,EI),n(67,EI),n(67,-Q),n(59,Q),n(59,-Q),n(52,W)
      ]
      input = 'E4:ei D4 C4 -ei E4:s -ei. F4:ei G4 -q B3 -q E3:w'
      sequence(input).should == expected
    end

    it 'should sequence repeated numeric pitches' do
      sequence('pit60*4').should == [n(60)]*4
    end

    it 'should sequence intervals' do
      sequence('C4 M2 m2').should == [n(60),n(62),n(63)]
    end
  end


  describe 'Other Constructs' do
    it 'should sequence repetitions' do
      expected = [
        n(67,EI),n(65,EI),n(67,EI),n(65,EI),n(67,EI),n(65,EI),n(64,EI),n(62,EI),
        n(67,EI),n(65,EI),n(67,EI),n(65,EI),n(67,EI),n(65,EI),n(64,EI),n(62,EI),
        n(60,EI),n(60,EI),n(60,EI),n(60,EI),n(60,EI)
      ]
      sequence('((G4:ei F4)*3 E4 D4)*2 C4*5').should == expected
    end

    it 'should sequence count limits' do
      expected = [
        n(60),n(62),n(64),n(60),n(62),n(67),n(65),n(64),n(67),n(59),n(62),n(59),n(62),n(57),n(59),n(60)
      ]
      sequence('(C4 D4 E4)&5 (G4 F4 E4)&4 ((B3 D4)*2 A3)&6 C4').should == expected
    end

    it 'should sequence choices' do
      sequencer = Sequencer.new({:input => '( (C4 | E4 | G4)  (C5 | E5 | G5) )*8'})
      actual = []
      count = 0
      while event=sequencer.next_event and count < SEQUENCE_COUNT_LIMIT
        octave = count%2 * 12
        case event
        when n(60+octave),n(64+octave),n(67+octave) then ; # keep going
        else fail "event #{event.inspect} was not one of the expected values"
        end
        count += 1
      end
      if count == SEQUENCE_COUNT_LIMIT
        fail "#{input} output more than #{SEQUENCE_COUNT_LIMIT}" 
      end
    end

    it 'should sequence chaining' do
      expected = [
        n(67,Q,P),n(65,EI,MF),n(64,Q,FF),n(62,EI,P),
        n(67,Q,MF),n(65,EI,FF),n(64,Q,P),n(62,EI,MF),
        n(67,Q,FF),n(65,EI,P),n(64,Q,MF),n(62,EI,FF),
        n(67,Q,P),n(65,EI,MF),n(64,Q,FF),n(62,EI,P),
        n(60,Q,MF)
      ]
      sequence('((G4 F4 E4 D4)*4 C4):(q ei):(p mf ff)').should == expected
    end

    it 'should sequence variables' do
      expected = [
        n(67,120),n(69,120),n(70,120),n(71,120),
        n([48,55,64,72],960),n([48,55,63,72],960),n(36,1920)
      ]
      input = ' $C_MAJOR     = [C3 G3 E4 C5];
      $C_MINOR     = [C3 G3 Eb4 C5];
      $LEAD_IN     = G4 A4 Bb4 B4;
      $FINAL_PITCH = C2;
      $LEAD_IN:s $C_MAJOR:h $C_MINOR:h $FINAL_PITCH:w'
      sequence(input).should == expected 
    end

    it 'should sequence commands' do
      $X = 0
      sequence('1 {{$X=25}} 2').should == [1,2] 
      $X.should == 25
    end
  end


  describe 'Implicit Values' do
    it 'should use the default octave when the first octave is implicit' do
      for note_name in 'A'..'G' do
        sequence(note_name).should == [note(Pitch.new(PITCH_CLASS[note_name], DEFAULT_OCTAVE))]
      end
    end

    it 'should use the previous octave for implicit octaves by default' do
      sequence('C4 C D# Bb').should == pitches(60,60,63,70)
      sequence('C5 C D# Bb').should == pitches(72,72,75,82)
      sequence('C4 (C B3)*2').should == pitches(60,60,59,48,59)
    end  
  end 

end
