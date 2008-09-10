require "test/unit"
require 'sequencer'

class TestSequencer < Test::Unit::TestCase
  
  def sequence input
    seq = Sequencer.new(input)
    assert_not_nil(seq.tree, 
      "Failed to parse: #{input}\n" + 
      "(#{seq.parser.failure_line},#{seq.parser.failure_column}): #{seq.parser.failure_reason}")
    return seq
  end
  
  
  def assert_done seq
      assert_nil(seq.next)
  end
  
  def assert_seq_equals expected, seq_str
    seq = sequence seq_str
    expected.each do |val|
      n = seq.next
      assert_not_nil(n)
      assert_equal val, n # seq.next
    end
    assert_done seq        
  end
  
  def test_single_element
    assert_seq_equals [1], '1'
  end

  def test_simple_sequence
    assert_seq_equals [1, 2], '1 2'
  end
  
  def test_single_chord
    assert_seq_equals [[1,2,3]], '[1 2 3]'
  end
  
  def test_chord_sequence
    assert_seq_equals [[1,2],[3,4],[5,6,7]], '[1 2] [3 4] [5 6 7]'
  end
  
  def test_chord_and_number_sequence
    assert_seq_equals [1, [2,3], 4, [5,6]], '1 [2 3] 4 [5 6]'
  end
  
  def test_repeated_sequence
    assert_seq_equals   [1,1],      '1*2'
    assert_seq_equals   [1,1,1],    '(1)*3'
    assert_seq_equals   [],         '(1)*0'
    assert_seq_equals   [],         '(1)*-1'
    assert_seq_equals   [1,2],      '(1 2)*1'
    assert_seq_equals   [1,2,1,2],  '(1 2)*2'
    assert_seq_equals   [],         '(1 2)*0'
  end
  
  def test_repeated_sequence_with_eval_repetitions
    assert_seq_equals [1,2,1,2], '(1 2)*{8/4}'
  end
  
  def test_nested_repetitions
    assert_seq_equals [1,2,3,2,3,1,2,3,2,3], '(1 (2 3)*2)*2'
  end

  def test_limited_repeat_sequence
    assert_seq_equals   [1,1,1,1],  '1&4'
    assert_seq_equals   [1,1,1,1],  '1&4'
    assert_seq_equals   [1,2,1,2],  '(1 2)&4'
    assert_seq_equals   [1,2,3,1],  '(1 2 3)&4'
  end
  
  # repeated chord
  
  # "real" chains 1:2:3
  
  # complex chains (1 2):(3 4)
  
  # nested chains?  (1:2  3:4):(5  6  7) should produce 1:2:5  3:4:6  1:2:7
  
end