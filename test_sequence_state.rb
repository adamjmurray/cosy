require "test/unit"
require 'sequence_state'

class TestSequencer < Test::Unit::TestCase
  
  PARSER = SequencingGrammarParser.new
  
  def get_state input
    seq = PARSER.parse input
    SequenceState.new seq
  end
  
  def test_no_limit
    ['1 2 3', '(1 2 3)'].each do |seq|
      state = get_state seq
      assert_equal(1, state.iteration_limit)
      assert_nil(state.count_limit)      
    end
  end
  
  def test_iteration_limit
    [-1, 0, 2, 3.5].each do |limit|
      state = get_state "(1 2 3)#{OP_ITER_LIMIT}#{limit}"
      assert_equal(limit, state.iteration_limit)
      assert_nil(state.count_limit)
    end
  end
  
  def test_count_limit
    [-1, 0, 2, 3.5].each do |limit|
      state = get_state "(1 2 3)#{OP_COUNT_LIMIT}#{limit}"
      assert_equal(limit, state.count_limit)
      assert_nil(state.iteration_limit)
    end
  end
  
  # todo: test advancing and increasing count, and within_limits?
  # but first I want to flesh out the sequencing implementation so I
  # don't have to redo all of this
  
end