require File.dirname(__FILE__)+'/spec_helper'

describe Cosy::SymbolTable do
  
  def create_table(variables=[], magic_variables=[])
    table = SymbolTable.new
    variables.each{ |key,val| table[key] = val }
    magic_variables.each{ |val| table.push_magic_variable(val) }
    return table
  end
  
  it 'should support variable storage and lookup' do
    table = SymbolTable.new
    table.lookup(:var).should == nil
    table[:var] = 1
    table.lookup(:var).should == 1
    table[:var] = 2
    table.lookup(:var).should == 2
    
    table.lookup(:var2).should == nil
    table[:var2] = 0
    table.lookup(:var2).should == 0
    table.delete(:var2)
    table.lookup(:var2).should == nil
    table.lookup(:var).should == 2
  end
  
  it "should manage a stack of 'magic' variables" do
    table = SymbolTable.new
    assert_magic_variables table, [nil,nil,nil]
    
    table.push_magic_variable(1)
    assert_magic_variables table, [1,nil,nil]
    
    table.push_magic_variable(2)
    assert_magic_variables table, [2,1,nil]
    
    table.push_magic_variable(3)
    assert_magic_variables table, [3,2,1]
    table.lookup("$$$").should == 1 # sanity check
    
    table.pop_magic_variable.should == 3
    assert_magic_variables table, [2,1,nil]
    
    table.pop_magic_variable.should == 2
    assert_magic_variables table, [1,nil,nil]
    
    table.pop_magic_variable.should == 1
    assert_magic_variables table, [nil,nil,nil]
    
    table.pop_magic_variable.should == nil
    assert_magic_variables table, [nil,nil,nil]
  end
  
  def assert_magic_variables(table, expected_vars)
    var = ""
    expected_vars.each do |expected|
       # first iteration look up '$', then '$$', then '$$$', etc
      var += "$"
      table.lookup(var).should == expected
    end
  end
  
  it 'should prevent setting magic variables directly' do
    table = SymbolTable.new
    lambda{ table['$'] = 'foo' }.should raise_error(RuntimeError)
    lambda{ table['$$'] = 'foo' }.should raise_error(RuntimeError)
  end

  it 'should find variables in a parent symbol table' do
    parent_table =  SymbolTable.new
    parent_table[:a] = 'a'    
    table = SymbolTable.new(parent_table)
    table[:b] = 'b'
    table[:b].should == 'b'
    table[:a].should == nil
    table.lookup(:b).should == 'b'
    table.lookup(:a).should == 'a'
  end
  
  it 'should find magic variables in a parent symbol table' do
    parent_table =  SymbolTable.new
    parent_table.push_magic_variable(1)
    parent_table.push_magic_variable(2)
    
    table = SymbolTable.new(parent_table)
    assert_magic_variables table, [2,1,nil]
  
    table.push_magic_variable(3)
    assert_magic_variables table, [3,2,1]
    
    table.pop_magic_variable.should == 3
    
    # shouldn't pop magic variables in the parent:
    table.pop_magic_variable.should == nil
    assert_magic_variables table, [2,1,nil]    
  end
  
end