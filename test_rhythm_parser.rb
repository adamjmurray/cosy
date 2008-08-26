require "test/unit"
require 'rhythm_parser'

class TestRhythmParser < Test::Unit::TestCase
  
  PARSER = RhythmGrammarParser.new
  
  ALL_DURATIONS = %w{W w H h Q q E e S s R r X x}
  
  def parse input
    output = PARSER.parse(input)
    assert_not_nil(output, 
      "Failed to parse: #{input}\n" + 
      "(#{PARSER.failure_line},#{PARSER.failure_column}): #{PARSER.failure_reason}")
    return output
  end
  
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
end
