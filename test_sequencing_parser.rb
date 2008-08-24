require "test/unit"
require 'sequencing_grammar_parser'

class TestEvent < Test::Unit::TestCase
  
  PARSER = SequencingGrammarParser.new

  def parse input
    output = PARSER.parse(input)
    assert_not_nil(output, "Failed to parse: #{input}")
    return output
  end
  
  def assert_parse_failure invalid_syntax
    output = PARSER.parse(invalid_syntax)
    assert_nil(output, "Successfully parsed invalid syntax: #{invalid_syntax}")
    return nil
  end

  def test_parse_int
    # todo: a better way to check the value
    out = parse '0'
    assert_equal(0, out.value[0].value)
    out = parse '2'
    assert_equal(2, out.value[0].value)
    out = parse '789'
    assert_equal(789, out.value[0].value)
    out = parse '-1'
    assert_equal(-1, out.value[0].value)
  end
  
  def test_parse_float
    out = parse '0.0'
    assert_equal(0.0, out.value[0].value)
    out = parse '2.5'
    assert_equal(2.5, out.value[0].value)
    out = parse '789.654321'
    assert_equal(789.654321, out.value[0].value)
    out = parse '-1.204'
    assert_equal(-1.204, out.value[0].value) 
  end
  
  def test_parse_whitespace
    parse ''
    parse ' '
    parse '   '
    parse "\t"
    parse "\n"
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
  
  def test_misc
    parse '[2 c4] 3 (4.0 (6)*3)*2'
    parse '[2 c#+4] 3 (4.0 6*3)*2'
    parse '[fb3 c#+4]*3 (4.0*5 6*3)*2'
    parse '[fb3 c#+4]*3 ((4.0 5*5)*5 6*3)*2'
    parse '(c4 5)*1.5 [3 4]*3'
  end

  def test_invalid_syntax
    assert_parse_failure 'x'
    assert_parse_failure '1.'
    assert_parse_failure '1 2)*3'
  end 
  
end