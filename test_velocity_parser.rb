require "test/unit"
require 'velocity_parser'

class TestVelocityParser < Test::Unit::TestCase
  
  PARSER = VelocityGrammarParser.new
  
  ALL_VELOCITIES = %w{ppp pp p mp mf f ff fff}
  
  def parse input
    output = PARSER.parse(input)
    assert_not_nil(output, 
      "Failed to parse: #{input}\n" + 
      "(#{PARSER.failure_line},#{PARSER.failure_column}): #{PARSER.failure_reason}")
    return output
  end
  
  def test_parse_base_durations
   ALL_VELOCITIES.each do |vel|
      parse vel
    end
  end

end
