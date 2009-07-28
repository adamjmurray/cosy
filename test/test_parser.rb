require 'test/unit'
$:.unshift File.dirname(__FILE__)+'/../lib'
require 'cosy'

# These tests check that the grammar and parser accept 
# the input that they was designed to accept.

class TestParser < Test::Unit::TestCase
  include Cosy  
  PARSER = SequenceParser.new

  def parse input
    output = PARSER.parse(input)
    assert_not_nil(output, 
      "Failed to parse: #{input}\n" + 
      "(#{PARSER.failure_line},#{PARSER.failure_column}): #{PARSER.failure_reason}")
    return output
  end
  
  def assert_failure invalid_syntax
    assert_raises(RuntimeError) { PARSER.parse(invalid_syntax) }
  end




  def test_negative_duration_multiplier
    DURATION.keys.each_with_index do |dur,index|
      parse "-#{index}#{dur}"
      parse "-#{index}#{dur.upcase}" if dur.length == 1
    end
  end
  
  def test_negative_duration
    DURATION.keys.each_with_index do |dur,index|
      parse '-' + dur
      parse '-' + dur.upcase if dur.length == 1
    end  
  end

  def test_multiplier_triplet_dotted_durations
    %w{ .t  t. ..t .t. t.. tt. t.t .tt ..t.tt...t.t }.each_with_index do |mod,index|
      DURATION.keys.each do |dur|
        parse index.to_s + dur + 't' + mod
        parse index.to_s + dur.upcase + 't' + mod if dur.upcase == 1
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
  
  def test_foreach
    parse '(1 2)@(3 4)'
    parse '(1 $ 2)@(3 4)'
  end
  
  def test_multi_foreach
    parse '(1 2)@(3 4)@(5 6)'
  end
  
  def test_nested_foreach
    parse '((1 2)@(3 4))@(5 6)'
    parse '((1 $ 2 $$)@(3 4 $))@(5 6)'
  end

  def test_assign_variable
    parse '$X=1 2 3 4; $X'
    parse '$X=1 2 3 4; $Y=5; $X $Y'   
  end
  
  def test_label
    parse '#label:5'
    parse '#1:c:mf'
    parse '#env:[1 250 1 500 0 250]'
  end
  
  def test_parallel
    parse 'a == b'
  end
 
end