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
  
  def assert_parse_failure invalid_syntax
    output = PARSER.parse(invalid_syntax)
    assert_nil(output, "Successfully parsed invalid syntax: #{invalid_syntax}")
    return nil
  end
  
  def assert_generator_done(gen)
      assert(!gen.next?, "Was not expected more values")
  end
  
  def parse_numbers(numbers, &block)
    numbers.each do |n|
      gen = parse(n.to_s)
      assert_equal(n, gen.next)
      assert_generator_done(gen)
    end
  end
  
  def test_parse_ints
    parse_numbers [0, 2, 789, -1]
  end
  
  def test_parse_float
    parse_numbers [0.0, 2.5, 789.654321, -1.0001]
  end
  
  def test_parse_whitespace
    ['', ' ', '   ', "\t", "\n"].each do |str|
      gen = parse(str)
      assert_generator_done(gen)
    end
  end
  
  def test_parse_string
    parse '"a b c"'
    parse '"a b\\" c"'
    parse '"a b c" "a b\\" c"'
    parse "'a b c'"  
    parse "'a b\\' c'"  
    parse "'a b c' 'a b\\' c'"  
    parse '"foo bar" \'baz\''
  end
  
  def test_parse_ruby
    parse "{1 + 2} {'}'} {\"}\"}"
    
  end
  
  def test_parse_parenthesized_sequence
    parse '(1 2 3)'
    parse '(1 2 3) '
    parse ' (1 2 3)'
    parse '(1 2 3 ) '
    parse '( 1 2 3)'
    parse ' ( 1   2  3 )    '
  end

  def test_parse_parenthesized_sequence_then_unparen
    parse '(1 2) 3'
    parse ' ( 1  2 )   3 '
  end
  
  def test_non_parenthesized_sequence_then_paren
    parse '1 (2 3)'
    parse ' 1   ( 2  3 )  '
  end
      
  def test_parse_seqeunce_of_parenthesized_sequences
    parse '(1 2 3) (4 5 6)'
    parse '  ( 1 2  3 )   ( 4  5  6 ) '
  end
  
  def test_parse_chord
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
  
  def test_parse_repeated_sequence
    gen = parse '1*2'
    2.times do
      assert_equal(1, gen.next)
    end
    assert_generator_done(gen)
    
    gen = parse '(1)*2'
    2.times do
      assert_equal(1, gen.next)
    end
    assert_generator_done(gen)
    
    gen = parse '(1 2)*2'
    2.times do
      assert_equal(1, gen.next)
      assert_equal(2, gen.next)
    end
    assert_generator_done(gen)
    
    gen = parse '(1 2)*0'
    assert_generator_done(gen)
    
    gen = parse '(1 2)*-1'
    assert_generator_done(gen)
  end
  
  def test_parse_repeated_sequence_with_eval_repetitions
    gen = parse '(1 2)*{8/4}'
    2.times do
      assert_equal(1, gen.next)
      assert_equal(2, gen.next)
    end
    assert_generator_done(gen)
  end
  
  

  def test_parse_limited_repeat_sequence
    gen = parse '1&4'
    4.times do
      assert_equal(1, gen.next)
    end
    assert_generator_done(gen)
    
    gen = parse '(1)&4'
    4.times do
      assert_equal(1, gen.next)
    end
    assert_generator_done(gen)
    
    gen = parse '(1 2)&4'
    2.times do
      assert_equal(1, gen.next)
      assert_equal(2, gen.next)
    end
    assert_generator_done(gen)
    
    gen = parse '(1 2 3)&4'
    assert_equal(1, gen.next)
    assert_equal(2, gen.next)
    assert_equal(3, gen.next)
    assert_equal(1, gen.next)
    assert_generator_done(gen)    
  end
  
  def test_parse_fractional_repeated_sequence
    parse '1*2.2'
    parse '(1)*2.20'
    parse '(1 2)*2.210'  
  end
  
  def test_parse_sequence_of_repeated_sequences
    parse '(1 2)*2 (3 4)*2.5 (6 7 8)*20'
  end
  
  def test_parse_sequence_of_parenthesized_and_repeated_sequences
    parse '(1 2)*2 (3 4) (6 7 8)*20'  
  end
  
  def test_parse_chord_sequence
    parse '[1] [2] [3]'
    parse '[1 2 3] [4 5 6] [7 8 9]'
  end
  
  def test_parse_repeated_chord
    parse '[1]*2'
    parse '[1 2]*2'
  end
  
  def test_parse_repeated_chord_sequence
    parse '[1]*2 [3]'
    parse '[1 2]*2 [3] [4 5 6]*3.2'
  end

  def test_parse_heterogonous_sequence
    parse '(c4 5)*1.5'
    parse '[3 4]*3'
    parse '(c4 5)*1.5 [3 4]*3'
    parse '[fb3 c#+4]*3 (4.0*5 6*3)*2'
    parse '[fb3 c#+4]*3 ((4.0 5*5)*5 6*3)*2'
    parse '[2 c4] 3 (4.0 (6)*3)*2'
    parse '[2 c#+4] 3 (4.0 6*3)*2'
  end
  
  ALL_VELOCITIES = %w{ppp pp p mp mf f ff fff}
  
  def test_parse_velocities
    ALL_VELOCITIES.each do |vel| 
      parse vel
    end
  end

  ALL_DURATIONS = %w{W w H h Q q E e S s R r X x}

  def test_parse_base_durations
    ALL_DURATIONS.each do |dur|
      parse dur
    end
  end

  def test_parse_triplet_durations
    ALL_DURATIONS.each do |dur|
      parse dur + 't'
    end
  end

  def test_parse_dotted_durations
    %w{ .  ..  ...  .... }.each do |dots|
      ALL_DURATIONS.each do |dur|
        parse dur + dots
      end
    end
  end

  def test_parse_triplet_dotted_durations
    %w{ .  ..  ...  .... }.each do |dots|
      ALL_DURATIONS.each do |dur|
        parse dur + 't' + dots
      end
    end
  end

  def test_parse_duration_multiplier
    ALL_DURATIONS.each_with_index do |dur,index|
      parse index.to_s + dur
    end
  end

  def test_parse_multiplier_triplet_dotted_durations
    %w{ .  ..  ...  .... }.each_with_index do |dots,index|
      ALL_DURATIONS.each do |dur|
        parse index.to_s + dur + 't' + dots
      end
    end    
  end

  def test_parse_element_chain
    parse '4:5 : C4'
    parse 'C4:mf:q.'
    parse '[C4 E4]:fff'
    parse '(4 5):(6 7)'
  end
  
  def test_parse_element_choice
    parse '4|5 | C4'
    parse 'C4|mf|q.'
    parse '[C4 E4]|fff'
    parse '(4 5)|(6 7)'
  end

  def test_parse_invalid_syntax
    assert_parse_failure '1.'
    assert_parse_failure '1 2)*3'
  end   
end