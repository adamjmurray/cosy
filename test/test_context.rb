require 'test/unit'
cosy_root = File.expand_path(File.dirname(__FILE__)+'/../lib/cosy')
require cosy_root
require cosy_root+'/model/syntax_tree'


class TestParser < Test::Unit::TestCase
  include Cosy
  
  def test_context_states
    s1 = Object.new
    s2 = Object.new
    context = Context.new(nil,nil,nil)
    
    context.states[s1][:iteration] = 0
    context.states[s2][:iteration] = 1
    context.states[s2][:count_limit] = 3
    context.states[s1][:count_limit] = 2
        
    assert_equal(0, context.states[s1][:iteration])
    assert_equal(1, context.states[s2][:iteration])
    assert_equal(2, context.states[s1][:count_limit])
    assert_equal(3, context.states[s2][:count_limit])
  end
end