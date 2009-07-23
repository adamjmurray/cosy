require File.dirname(__FILE__)+'/spec_helper'

describe Cosy::Pitch do
  
  it 'should generate text representations from numeric values' do
    Pitch.new(60).to_s.should == 'C4'
    Pitch.new(61).to_s.should == 'C#4'
  end
  
  it 'should have equivalent midi and pitchclass/accidental/octave represenations' do
    Pitch.new(63).should == Pitch.new(PITCH_CLASS['D'], 1, 4)
  end
  
end
  
describe Cosy::Interval do
  
  it 'should be equivalent to the number of semitones in the interval' do
    %w{p1 m2 M2 m3 M3 P4 aug4 P5 m6 M6 m7 M7}.each_with_index do |str,semitones|
      semitones.should == Interval.new(str)
    end
  end
  
  it 'should support alternate names for the intervals' do
    %w{dim2 aug1 dim3 aug2 dim4 aug3 dim5 dim6 aug5 dim7 aug6 dim8}.each_with_index do |str,semitones|
      semitones.should == Interval.new(str)
    end
  end
  
  it 'should support negative (descending) intervals' do
    %w{-p1 -m2 -M2 -m3 -M3 -P4 -aug4 -P5 -m6 -M6 -m7 -M7}.each_with_index do |str,index|
      semitones = -index
      semitones.should == Interval.new(str)
    end
  end
  
  it 'should support intervals over an octave' do
    %w{p8 m9 M9 m10 M10 P11 aug11 P12 m13 M13 m14 M14}.each_with_index do |str,semitones|
      semitones.should == Interval.new(str)
    end    
  end
    
  it 'should result in a pitch when added to a pitch' do
    Pitch.new(63).should == Pitch.new(PITCH_CLASS['C'], 0, 4) + Interval.new('m3')
  end
  
end
