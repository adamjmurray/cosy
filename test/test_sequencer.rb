require 'test/unit'
require 'set'
$:.unshift File.dirname(__FILE__)+'/../lib'
require 'cosy'

class TestSequencer < Test::Unit::TestCase
  include Cosy
  SEQUENCE_COUNT_LIMIT = 1000
  
  # define constants for intensities: P, PP, PPP, MP, etc
  INTENSITY.each do |key,value|
    const_set(key.upcase, value) if key.length <= 3
  end
  
  def sequence input
    return Sequencer.new(input)
  end
  
  def assert_done seq
    assert_nil(seq.next)
  end
  
  def assert_sequence(expected, input)
    if input.is_a? Sequencer
      seq = input
    else
      seq = sequence(input)
    end
    
    actual = []
    count = 0
    while val=seq.next and count < SEQUENCE_COUNT_LIMIT
      actual << val
      count += 1
    end
    if count == SEQUENCE_COUNT_LIMIT
      fail "#{input} output more than #{SEQUENCE_COUNT_LIMIT}" 
    end
    assert_equal(expected, actual)
  end
  
  def assert_failure(input)
    assert_raises(RuntimeError) { Sequencer.new(input) }
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
    assert_sequence   [1,2,3,1,2],  '(1 2 3)*1.5'
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
  
  def test_strings
    assert_sequence ['a','b','c'], "'a' 'b' 'c'"
    assert_sequence ['a','b','c'], '"a" "b" "c"'
  end
  
  def test_escaped_strings
    # checks to make sure we can sequence things like
    # "nested \\"quoted\\" strings"  and  'this test\'s confusing!'
    assert_sequence ['"',"'"], '\'"\' "\'"'
    assert_sequence ['"',"'"], "'\"' \"'\""
    assert_sequence ["'"], "'\\''"
    assert_sequence ['"'], '"\""'
  end
  
  def test_pitches
    assert_sequence [60,65,67,68,66], 'C4 F4 G4 Ab4 F#4'      
    assert_sequence [60,65,67,68,66], 'c4 f4 g4 ab4 F#4'      
    assert_sequence [0,5,7,8,6], 'C F G Ab F#'     
    assert_sequence [0,5,7,8,6], 'c f g ab f#'      
  end

  def test_numeric_pitches
    assert_sequence [60,65,67,68], 'y60 y65 y67 y68'      
    assert_sequence [60.0,65.5], 'y60.0 y65.5'
    assert_sequence [25.0], 'y100/4'
    assert_sequence [16], 'y{4**2}'          
  end
  
  def test_repeated_pitches
    assert_sequence [60,65,65,65,67,68,67,68], 'C4 F4*3 (G4 Ab4)*2'      
  end
  
  def test_chord
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
    assert_sequence [[60,120],[60,240],65], 'c4:(s i) f4'
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
    assert_sequence [1920,  960, 480, 240, 120, 60, 30], 'w h q i s r x'
    assert_sequence [1920,  960, 480, 240, 120, 60, 30], 'W H Q I S R X'
    assert_sequence [1920,  960, 480, 240, 120, 60, 60, 30, 30], 
        'whole half quarter eighth sixteenth thirtysecond thirty-second sixtyfourth sixty-fourth'
    assert_sequence [2880, 1440, 720, 360, 180, 90, 45], 'w. h. q. i. s. r. x.'
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
  
  def test_rhythm_numeric
    assert_sequence [100, 200, 300], 'u100 u200 u300'
    assert_sequence [100.5, 200.33, -30.0], 'u100.5 u200.33 u-30.0'
    assert_sequence [5.0/4], 'u5/4'
    assert_sequence [20], 'u{5*4}'
  end
  
  def test_velocity
    assert_sequence [PPP, PP, P, MP, MF, O, FF, FFF], 'ppp pp p mp mf o ff fff'
    assert_sequence [PP, P, MP, MP, MF, MF, O, FF], 
      'pianissimo piano mezzopiano mezzo-piano mezzoforte mezzo-forte forte fortissimo'
  end
  
  def test_numeric_velocity
    assert_sequence [1, 2, 3, 4], 'v1 v2 v3 v4'
    assert_sequence [1.1, 2.02, 3.0], 'v1.1 v2.02 v3.0'
    assert_sequence [10.0/3], 'v10/3'
    assert_sequence [7], 'v{9-2}'
    
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
    assert_sequence [1,1,2], '1 {node.parent.children[0].value} 2'
  end
  
  def test_self_aware_command
    assert_sequence [1,2,1], '1 2 {{node.parent.children.reverse!}} 3'
  end
  
  def test_restart_after_complete
    seq = sequence('1 2 3')
    assert_sequence([1,2,3], seq)
    seq.restart
    assert_sequence([1,2,3], seq)
    
    seq = sequence('1 (2 3)*2 (5 6):(7 8)')
    assert_sequence([1,2,3,2,3,[5,7],[6,8]], seq)
    seq.restart
    assert_sequence([1,2,3,2,3,[5,7],[6,8]], seq)
  end
  
  def test_restart_after_partial
    seq = sequence('1 (2 3)*2 (5 6):(7 8)')
    actual = []
    4.times{ actual << seq.next }
    seq.restart
    6.times{ actual << seq.next }
    seq.restart
    actual << seq.next
    assert_equal([1,2,3,2,  1,2,3,2,3,[5,7],  1], actual)
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