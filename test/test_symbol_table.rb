require 'test/unit'
cosy_root = File.expand_path(File.join(File.dirname(__FILE__), '/../lib/cosy'))
require File.join(cosy_root, 'sequencer/symbol_table')

class TestSymbolTable < Test::Unit::TestCase
  include Cosy
  
  def create_table(variables={}, magic_variables=[])
    table = SymbolTable.new
    variables.each{ |key,val| table[key] = val }
    magic_variables.each{ |val| table.push_magic_variable(val) }
    return table
  end
  
  def test_basic
    table = create_table({:a, 1}, [2, 3])
    assert_equal(1, table.lookup(:a))
    assert_equal(3, table.lookup('$'))
    assert_equal(2, table.lookup('$$'))    
    assert_equal(3, table.pop_magic_variable)
    assert_equal(2, table.pop_magic_variable)
    assert_nil(table.pop_magic_variable)
  end
  
  def test_scoping
    parent_table = create_table({:a, 1}, [2, 3])
    table = SymbolTable.new(parent_table)
    table[:b] = -1
    assert_equal(-1, table[:b])
    assert_nil(table[:a])
    assert_equal(-1, table.lookup(:b))
    assert_equal(1, table.lookup(:a))
    assert_equal(3, table.lookup('$'))
    assert_equal(2, table.lookup('$$'))    
    assert_nil(table.pop_magic_variable)
    
    table.push_magic_variable(4)
    assert_equal(4, table.lookup('$'))
    assert_equal(3, table.lookup('$$'))
    assert_equal(2, table.lookup('$$$'))    
    assert_equal(4, table.pop_magic_variable)
    
    assert_equal(3, table.lookup('$'))
    assert_equal(2, table.lookup('$$'))    
    assert_nil(table.pop_magic_variable)
  end
  
  def test_revent_magic_variable_overwrite
    table = create_table({:a, 1}, [2, 3])
    assert_raises(RuntimeError) { table['$'] = 'foo' } 
    assert_raises(RuntimeError) { table['$$'] = 'foo' } 
  end
  
end