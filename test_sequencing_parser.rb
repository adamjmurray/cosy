require "test/unit"
require 'sequencing_grammar_parser'

class TestSequencingParser < Test::Unit::TestCase
  
  PARSER = SequencingGrammarParser.new

  def parse input
    output = PARSER.parse(input)
    assert_not_nil(output, 
      "Failed to parse: #{input}\n" + 
      "(#{PARSER.failure_line},#{PARSER.failure_column}): #{PARSER.failure_reason}")
    return output
  end
  
  def assert_node_length expected_length, input
    assert_equal(expected_length, parse(input).length)
  end
  
  def assert_failure invalid_syntax
    output = PARSER.parse(invalid_syntax)
    assert_nil(output, "Successfully parsed invalid syntax: #{invalid_syntax}")
    return nil
  end

  def parse_numbers(numbers, &block)
    numbers.each do |n|
      tree = parse(n.to_s)
      assert_equal(n, tree.value)
    end
  end
  
  def test_ints
    parse_numbers [0, 2, 789, -1]
  end
  
  def test_float
    parse_numbers [0.0, 2.5, 789.654321, -1.0001]
  end
  
  def test_whitespace
    ['', ' ', '   ', "\t", "\n"].each do |str|
      parse str
    end
  end
  
  def test_string
    parse '"a b c"'
    parse '"a b\\" c"'
    parse '"a b c" "a b\\" c"'
    parse "'a b c'"  
    parse "'a b\\' c'"  
    parse "'a b c' 'a b\\' c'"  
    parse '"foo bar" \'baz\''
  end
  
  def test_ruby
    parse "{1 + 2} {'}'} {\"}\"}"
  end
  
  def test_sequence
    seq = parse '0 1 2 3'
    assert_equal(SequenceNode, seq.class)
    assert_equal(4, seq.value.length)
    seq.value.each_with_index do |item,index|
      assert_equal(index, item.value)
    end
  end

  def test_chain
    seq = parse '0:1:2:3*4'
    assert_equal(ChainNode, seq.class)
    assert_equal(4, seq.value.length)
    seq.value.each_with_index do |item,index|
      assert_equal(index, item.value)
    end
    assert_equal(5, seq.children.length)
    assert_equal(ModifierNode, seq.children.last.class)
  end
  
  def test_parenthesized_sequence
    parse '(1 2 3)'
    parse '(1 2 3) '
    parse ' (1 2 3)'
    parse '(1 2 3 ) '
    parse '( 1 2 3)'
    parse ' ( 1   2  3 )    '
  end

  def test_parenthesized_sequence_then_unparen
    parse '(1 2) 3'
    parse ' ( 1  2 )   3 '
  end
  
  def test_non_parenthesized_sequence_then_paren
    parse '1 (2 3)'
    parse ' 1   ( 2  3 )  '
  end
      
  def test_seqeunce_of_parenthesized_sequences
    parse '(1 2 3) (4 5 6)'
    parse '  ( 1 2  3 )   ( 4  5  6 ) '
  end
  
  def test_chord
    parse '[1]'
    parse '[1 2 3]'
    parse '[1.1]'
    parse '[1.1 2.2 3.3]'
    parse '[-1]'
    parse '[-1 -2 -3]'
    parse '[-1.1]'
    parse '[-1.1 -2.2 -3.3]'
    parse '[1.1 -2.2 3.33333]'
    parse '[C4]'
    parse '[C4 D4 E4]'
    parse '[C#4]'
    parse '[Cb7 D#+-1 Eb_5]'
    parse "['asdf' 'foo']"
  end
  
  def test_repeated_sequence
    parse '1*2'
    parse '(1)*2'
    parse '(1 2)*2'
    parse '(1 2)*0'
    parse '(1 2)*-1'
  end
  
  def test_repeated_sequence_with_eval_repetitions
    parse '(1 2)*{8/4}'
    end

  def test_limited_repeat_sequence
    parse '1&4'
    parse '(1)&4'
    parse '(1 2)&4'
    parse '(1 2 3)&4'
  end
  
  def test_fractional_repeated_sequence
    parse '1*2.2'
    parse '(1)*2.20'
    parse '(1 2)*2.210'  
  end
  
  def test_sequence_of_repeated_sequences
    parse '(1 2)*2 (3 4)*2.5 (6 7 8)*20'
  end
  
  def test_sequence_of_parenthesized_and_repeated_sequences
    parse '(1 2)*2 (3 4) (6 7 8)*20'  
  end
  
  def test_chord_sequence
    parse '[1] [2] [3]'
    parse '[1 2 3] [4 5 6] [7 8 9]'
  end
  
  def test_repeated_chord
    parse '[1]*2'
    parse '[1 2]*2'
  end
  
  def test_repeated_chord_sequence
    parse '[1]*2 [3]'
    parse '[1 2]*2 [3] [4 5 6]*3.2'
  end

  def test_heterogonous_sequence
    parse '(c4 5)*1.5'
    parse '[3 4]*3'
    parse '(c4 5)*1.5 [3 4]*3'
    parse '[fb3 c#+4]*3 (4.0*5 6*3)*2'
    parse '[fb3 c#+4]*3 ((4.0 5*5)*5 6*3)*2'
    parse '[2 c4] 3 (4.0 (6)*3)*2'
    parse '[2 c#+4] 3 (4.0 6*3)*2'
  end
  
  ALL_VELOCITIES = %w{ppp pp p mp mf f ff fff}
  
  def test_velocities
    ALL_VELOCITIES.each do |vel| 
      parse vel
    end
  end

  ALL_DURATIONS = %w{W w H h Q q E e S s R r X x}

  def test_base_durations
    ALL_DURATIONS.each do |dur|
      parse dur
    end
  end

  def test_triplet_durations
    ALL_DURATIONS.each do |dur|
      parse dur + 't'
    end
  end

  def test_dotted_durations
    %w{ .  ..  ...  .... }.each do |dots|
      ALL_DURATIONS.each do |dur|
        parse dur + dots
      end
    end
  end

  def test_triplet_dotted_durations
    %w{ .  ..  ...  .... }.each do |dots|
      ALL_DURATIONS.each do |dur|
        parse dur + 't' + dots
      end
    end
  end

  def test_duration_multiplier
    ALL_DURATIONS.each_with_index do |dur,index|
      parse index.to_s + dur
    end
  end

  def test_multiplier_triplet_dotted_durations
    %w{ .  ..  ...  .... }.each_with_index do |dots,index|
      ALL_DURATIONS.each do |dur|
        parse index.to_s + dur + 't' + dots
      end
    end    
  end

  def test_element_chain
    parse '4:5:C4'
    parse 'C4:mf:q.'
    parse '[C4 E4]:fff'
    parse '(4 5):(6 7)'
  end
  
  def test_element_choice
    parse '4|5 | C4'
    parse 'C4|mf|q.'
    parse '[C4 E4]|fff'
    parse '(4 5)|(6 7)'
  end
  
  def test_node_length
    assert_node_length(0, '')
    assert_node_length(0, '  ')
    assert_node_length(1, '1')
    assert_node_length(2, '1 2')
    assert_node_length(2, '(1 2)')
    
    assert_node_length(2, '1:2')
    assert_node_length(3, '1:2:3')
    assert_node_length(2, '1:2*2')
    assert_node_length(3, '1:2:3&3')
    
    # the value of these is a single subsequence (in parentheses), hence the length is 1
    assert_node_length(1, '(1 2)*2')
    assert_node_length(1, '(1 2)&3')
    assert_node_length(1, '(1:2)*2')
    assert_node_length(1, '(1:2:3)&3')
    
    assert_node_length(2, '(1:2):(3 4)')
    assert_node_length(2, '(1:2):(3 4)*2')
    assert_node_length(3, '(1:2):6:(3 4)')
  end

  def test_invalid_syntax
    assert_failure '1.'
    assert_failure '1 2)*3'
    assert_failure 'asdf'
  end   
end