require 'test/unit'
require 'set'
cosy_root = File.expand_path(File.join(File.dirname(__FILE__), '/../lib/cosy'))
require cosy_root

class TestParser < Test::Unit::TestCase
  include Cosy
  
  def test_intervals
    %w{p1 m2 M2 m3 M3 P4 aug4 P5 m6 M6 m7 M7}.each_with_index do |str,index|
      assert_equal(index, Interval.new(str))
    end
  end
  
  def test_negative_intervals
    %w{-p1 -m2 -M2 -m3 -M3 -P4 -aug4 -P5 -m6 -M6 -m7 -M7}.each_with_index do |str,index|
      assert_equal(-index, Interval.new(str))
    end
  end
  
  def test_intervals_alternate_names
    %w{dim2 aug1 dim3 aug2 dim4 aug3 dim5 dim6 aug5 dim7 aug6 dim8}.each_with_index do |str,index|
      assert_equal(index, Interval.new(str))
    end
  end
  
  def test_intervals_over_octave
    %w{p8 m9 M9 m10 M10 P11 aug11 P12 m13 M13 m14 M14}.each_with_index do |str,index|
      assert_equal(index, Interval.new(str))
    end    
  end
  
  def test_pitches
    assert_equal Pitch.new(63), Pitch.new(PITCH_CLASS['D'], 1, 4)
  end
  
  def test_pitch_plus_interval
    assert_equal(Pitch.new(63), Pitch.new(PITCH_CLASS['C'], 0, 4) + Interval.new('m3'))
  end
    
end