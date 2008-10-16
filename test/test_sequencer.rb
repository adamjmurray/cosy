require 'test/unit'
require 'set'
cosy_root = File.expand_path(File.join(File.dirname(__FILE__), '/../lib/cosy'))
require File.join(cosy_root, 'sequencer/sequencer')


class TestSequencer < Test::Unit::TestCase
  include Cosy
  SEQUENCE_COUNT_LIMIT = 1000
  
  def sequence input
    sequencer = Sequencer.new(input)
    p = sequencer.parser
    assert_not_nil(sequencer.sequence, 
      "Failed to parse: #{input}\n" + 
      "(#{p.failure_line},#{p.failure_column}): #{p.failure_reason}")
    return sequencer
  end
  
  def assert_done seq
    assert_nil(seq.next)
  end
  
  def assert_sequence(expected, input)
    seq = sequence(input)
    actual = []
    count = 0
    val = seq.next
    while val and count < SEQUENCE_COUNT_LIMIT
      actual << val
      count += 1
      val = seq.next
    end
    if count == SEQUENCE_COUNT_LIMIT
      fail "#{input} output more than #{SEQUENCE_COUNT_LIMIT}" 
    end
    assert_equal(expected, actual)
  end
  
  def assert_failure(input)
    sequencer = Sequencer.new(input)
    assert_nil(sequencer.sequence, 
      "Successfully parsed invalid syntax: #{input}")
  end
  
  def test_infinite_loop_prevention
    assert_raises(RuntimeError) { assert_sequence [], "1*#{SEQUENCE_COUNT_LIMIT+1}" }
  end
  
  def test_single_element
    assert_sequence [1], '1'
  end
  
  def test_simple_sequence
    assert_sequence [1, 2], '1 2'
  end
  
  def test_single_chord
    assert_sequence [[1,2,3]], '[1 2 3]'
  end
  
  def test_numeric_chord_sequence
    assert_sequence [[1,2],[3,4],[5,6,7]], '[1 2] [3 4] [5 6 7]'
  end
  
  def test_chord_and_number_sequence
    assert_sequence [1, [2,3], 4, [5,6]], '1 [2 3] 4 [5 6]'
  end
  
  def test_repeated_sequence
    assert_sequence   [1,1],      '1*2'
    assert_sequence   [1,1,1],    '(1)*3'
    assert_sequence   [],         '1*0'
    assert_sequence   [],         '1*-1'
    assert_sequence   [1,2],      '(1 2)*1'
    assert_sequence   [1,2,1,2],  '(1 2)*2'
    assert_sequence   [],         '(1 2)*0'
    assert_sequence   [],         '(1 2)*-1'
  end
  
  def test_heterogenous_repeated_sequence
    assert_sequence [0,1,1,1,2,3,2,3,[4,5],[4,5],[4,5]],
      '0 1*3 (2 3)*2 [4 5]*3'
  end
  
  def test_repeated_sequence_with_eval_repetitions
    assert_sequence [1,2,1,2], '(1 2)*{8/4}'
    assert_sequence [1,1,1,1], '1*{2**2}'
  end
  
  def test_fractional_repetitions
    assert_sequence   [1,2,1,2,1],  '(1 2)*2.5'
    assert_sequence   [1,2,1,2,1],  '(1 2)*5/2'
    assert_sequence   [1,2,3,1],    '(1 2 3)*1.3'
    assert_sequence   [1,2,3,1,2],  '(1 2 3)*1.4'
    assert_sequence   [1,2,3,1],    '(1 2 3)*4/3'
  end
  
  def test_nested_repetitions
    assert_sequence [1,2,3,2,3,1,2,3,2,3], '(1 (2 3)*2)*2'
  end
  
  def test_count_limit
    assert_sequence   [1,1,1,1],    '1&4'
    assert_sequence   [1,1,1,1],    '(1)&4'
    assert_sequence   [1,1,1,1],    '1&8/2'
    assert_sequence   [],           '1&0'
    assert_sequence   [],           '1&-1'
    assert_sequence   [1,2,1,2],    '(1 2)&4'
    assert_sequence   [1,2,1,2,1],  '(1 2)&5'
    assert_sequence   [1,2,3,1],    '(1 2 3)&4'
    assert_sequence   [],           '(1 2)&0'
    assert_sequence   [],           '(1 2)&-1'    
  end
  
  def test_eval_count_limit
    assert_sequence [1,2],     '(1 2)&{8/4}'
    assert_sequence [1,1,1,1], '1&{2**2}'    
    assert_sequence [1,2,3,1], '(1 2 3)&{2**2}'    
  end
  
  def test_nested_count_limit
    assert_sequence [1,2,3,2,1,2,3,2,1], '(1 (2 3)&3)&9'
  end
  
  def test_count_limit_and_repeat
    assert_sequence [1,2,3,2,3,2,3,1,2], '(1 (2 3)*3)&9'
  end
  
  def test_notes
    assert_sequence [60,65,67,68], 'C4 F4 G4 Ab4'      
  end
  
  def test_repeated_notes
    assert_sequence [60,65,65,65,67,68,67,68], 'C4 F4*3 (G4 Ab4)*2'      
  end
  
  def test_note_chord
     assert_sequence [[60,65,67,68]], '[C4 F4 G4 Ab4]'      
  end
  
  def test_chord_sequence
    assert_sequence [[60,65],[67,68]], '[C4 F4] [G4 Ab4]'
  end
  
  def test_repeated_chord
    assert_sequence [[60,65],[60,65]], '[C4 F4]*2'      
    assert_sequence [[60,65],[60,65]], '([C4 F4])*2'      
  end
  
  def test_simple_chain
    assert_sequence [[1,2]],   '1:2'
    assert_sequence [[1,2,3]], '1:2:3'
  end
  
  def test_simple_chain_sequence
    assert_sequence [[1,2],[3,4,5]], '1:2 3:4:5'
  end
  
  def test_simple_choice
    seq = sequence '(1 | 2 | 3)'
    expected = [1,2,3]
    actual = Set.new
    100.times do
      seq.restart
      n = seq.next
      actual.add(n)
    end
    # may occasionally fail, since choices are random
    assert_equal(expected.to_set, actual)
    assert_done seq
  end
  
  def test_note_choice
    seq = sequence '(C4 | E4 | G4)'
    expected = [60,64,67]
    actual = Set.new
    100.times do
      seq.restart
      n = seq.next
      actual.add(n)
    end
    # may occasionally fail, since choices are random
    assert_equal(expected.to_set, actual)
    assert_done seq
  end
  
  def test_chord_choice
     seq = sequence '([C4 G4]| [D4 G4] | G4)'
     expected = [[60,67],[62,67],67]
     actual = Set.new
     100.times do
       seq.restart
       n = seq.next
       actual.add(n)
     end
     # may occasionally fail, since choices are random
     assert_equal(expected.to_set, actual)
     assert_done seq
   end
  
  def test_sequence_of_choices
    seq = sequence '(1 | 2 | 3) (C4|E4|G4)'
    expected1 = [1,2,3]
    expected2 = [60,64,67]
    actual = Set.new
    actual1 = Set.new
    actual2 = Set.new
    200.times do |n|
      seq.restart
      n = seq.next
      actual1.add(n)
      actual.add(n)
      n = seq.next
      actual2.add(n)
      actual.add(n)
    end
    # may occasionally fail, since choices are random
    assert_equal(expected1.to_set, actual1)
    assert_equal(expected2.to_set, actual2)
    assert_equal((expected1+expected2).to_set, actual)
    assert_done seq
  end
  
  def test_chain_secondary_list
    assert_sequence [[60,120],[60,240],65], 'c4:(s e) f4'
  end
  
  def test_complex_chain_same_length
    assert_sequence [[1,3],[2,4]], '(1 2):(3 4)'
  end
  
  def test_complex_chain_same_length_in_sequence
    assert_sequence [[1,3],[2,4],5], '(1 2):(3 4) 5'
  end
    
  def test_complex_chain_different_length
    assert_sequence [[1,3],[2,4],[1,5]], '(1 2):(3 4 5)'
    assert_sequence [[1,3,6],[2,4,7],[1,5,8],[2,3,9]], '(1 2):(3 4 5):(6 7 8 9)'     
  end
  
  def test_complex_chain_with_repetition
    assert_sequence [[1,3,6],[2,4,7],[1,5,8],[2,3,6]], '(1 2)*2:(3 4 5):(6 7 8)'     
    assert_sequence [[1,3,6],[2,4,7],[1,5,8],[2,3,6]], '(1 2):(3 4 5)&4:(6 7 8)'     
  end
  
  def test_nested_chain
    assert_sequence [ [[1,2],5],[[3,4],6],[[1,2],7] ], '(1:2 3:4):(5 6 7)'
  end
  
  def test_rhythm_basic
    assert_sequence [1920,  960, 480, 240, 120, 60, 30], 'w h q e s r x'
    assert_sequence [2880, 1440, 720, 360, 180, 90, 45], 'w. h. q. e. s. r. x.'
  end
  
  def test_rhythm_comprehensive
    base_expect = DURATION.values
    base_input = DURATION.keys
    tests = { 
      1 => '',
      1.5 => '.',
      1.5**2 => '.'*2,
      1.5**3 => '.'*3,
      2.0/3 => 't',
      2.0/3 * 1.5 => 't.',
      1.5 * 2.0/3 => '.t',
      1.5 * 2.0/3 => '.t',
      4.0/5 => ['4/5','']  # quintuplets!
    }
    tests.each_pair do |multiplier,modifier|
      premod = ''
      if modifier.is_a? Array
        premod = modifier[0]
        modifier = modifier[1]
      end
      expected = base_expect.map{|val| val*multiplier}
      input = base_input.map{|val|premod+val+modifier}.join(' ')
      assert_sequence expected, input
    end
  end
  
  def test_variables
    assert_sequence [1,2,3,4], '$X=1 2 3 4; $X'
    assert_sequence [1,2,3,4,5], '$X=1 2 3 4; $Y=5; $X $Y'
    assert_sequence [1,2,3,4,5,[6,7]], '$X=1 2 3 4; $Y=5; $Z=[6 7]; $X $Y $Z'
    assert_sequence [1,2,3,4,[5,100],[6,7]], '$X=1 2 3 4; $Y=5; $Z=[6 7]; $X $Y:100 $Z'
  end
  
  def test_foreach_basic
    assert_sequence [1,3,2,3], '(1 2)@($ 3)'
    assert_sequence [1,3,1,2,3,2], '(1 2)@($ 3 $)'
    assert_sequence [1,3,1,2,3,2,1,3,1], '(1 2 1)@($ 3 $)'
  end
  
  def test_foreach_in_sequence
    assert_sequence [0,1,3,2,3,0], '0 (1 2)@($ 3) 0'
    assert_sequence [0,1,3,1,2,3,2,0], '0 (1 2)@($ 3 $) 0'
    assert_sequence [0,1,3,1,2,3,2,1,3,1,0], '0 (1 2 1)@($ 3 $) 0'
  end
  
  def test_foreach_nested
    assert_sequence [1,3,5,1,4,5,2,3,5,2,4,5], '(1 2)@(3 4)@($$ $ 5)' 
    assert_sequence [1,3,5,1,4,5,2,3,5,2,4,5], '(1 2)@((3 4)@($$ $ 5))'  
  end
  
  def test_foreach_complex_subsequence
    assert_sequence [1,9,2,9,3,9,2,9], '(1 (2 3)&3)@($ 9)'
    assert_sequence [1,1,9,2,2,9,3,3,9,2,2,9], '(1 (2 3)&3)@($*2 9)'
  end
  
  def test_foreach_repetition
    assert_sequence [1,3,2,3,1,3,2,3], '((1 2)@($ 3))*2'
    assert_sequence [1,3,2,3,1,3,2], '((1 2)@($ 3))&7'
  end

  def test_tempo  
    assert_sequence [1,2,3], 'TEMPO=1; QNPM=2; QPM=3'
  end
  
  def test_program  
    assert_sequence [1,2], 'PROGRAM=1; PGM=2'
    assert_sequence [1,2], 'PROGRAM=1; PGM=2;'
  end
  
  def test_ruby
    assert_sequence [1,7,2], '1 {3+4} 2'
  end
  
  def test_command
    $X = 0
    assert_sequence [1,2], '1 {{$X=25}} 2'
    assert_equal(25, $X)
  end
  
  def test_self_aware_ruby
    # TODO: I don't like that we need to call value, maybe rethink the interface,
    # or provide some convenience methods...
    assert_sequence [1,1,2], '1 {sequence.children[0].value} 2'
  end
  
  def test_self_aware_command
    assert_sequence [1,2,1], '1 2 {{sequence.children.reverse!}} 3'
  end

  def test_invalid_sequence
    assert_failure '1.'
    assert_failure '1 2)*3'
    assert_failure 'asdf'
  end

  # full melodic (note, rhythm, velocity) sequence
      
  # complex choices
  # 'c4 ([c4 g4]*2 | [b2 b3 b4]*2)'
  # 'nested' choices

  
end