require File.dirname(__FILE__)+'/spec_helper'

describe Cosy::Context do

  it 'should manage states per-object' do
    n1 = "node1"
    n2 = "node2"
    context = Context.new(nil,nil,nil)
    
    context.states[n1][:iteration] = 0
    context.states[n2][:iteration] = 1
    context.states[n2][:count_limit] = 3
    context.states[n1][:count_limit] = 2
        
    context.states[n1][:iteration].should == 0
    context.states[n2][:iteration].should == 1
    context.states[n1][:count_limit].should == 2
    context.states[n2][:count_limit].should == 3
  end
  
  it 'should track node visits' do
    n = "node"
    context = Context.new(nil,nil,nil)

    context.visited?(n).should == false
    context.visit_count(n).should == 0

    context.mark_visit(n)
    context.visited?(n).should == true
    context.visit_count(n).should == 1

    context.mark_visit(n)
    context.visited?(n).should == true
    context.visit_count(n).should == 2

    context.clear_visits(n)
    context.visited?(n).should == false
    context.visit_count(n).should == 0
  end
  
  it 'should track hierarchical context via a stack of nodes' do
    root = "root"
    n1 = "node1"
    n2 = "node2"
    n3 = "node3"
    context = Context.new(nil,nil,root)

    context.node.should == root

    context.enter(n1)
    context.enter(n2)
    context.enter(n3)
    context.node.should == n3
    
    context.exit.should == n2
    context.exit.should == n1
    context.node.should == n1
    context.exit.should == root    
    context.exit.should == nil
  end
  
  it 'should handle count limits and exits up to the node whose limit gets exceeded' do
    n1 = "node1"
    n2 = "node2"
    n3 = "node3"
    context = Context.new(nil,nil,nil)

    context.enter(n1)
    context.enter(n2)
    # we can increment the count 3 times before we exceed this limit:
    context.create_count_limit(n2, 3) 
    context.enter(n3)
    
    context.node.should == n3
    context.increment_count.should == true
    context.increment_count.should == true
    context.increment_count.should == true
    
    context.increment_count.should == false
    context.node.should == n2    
  end
  
end
