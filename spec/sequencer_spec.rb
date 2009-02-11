require File.dirname(__FILE__)+'/spec_helper'

describe Cosy::Sequencer do
    
  describe 'Ruby Support' do
    
    it 'should re-evaluate Ruby values for numeric pitches' do
      $x = nil
      sequence('pit{$x ||= 0; $x += 1}*3').should == [1,2,3]
    end
    
    it 'should re-evaluate Ruby values for numeric intervals' do
      $x = nil
      sequence('i{$x ||= 0; $x += 1}*3').should == [1,2,3]
    end
    
    it 'should re-evaluate Ruby values for numeric velocities' do
      $x = nil
      sequence('v{$x ||= 0; $x += 1}*3').should == [1,2,3]
    end

    it 'should re-evaluate Ruby values for numeric durations' do
      $x = nil
      sequence('dur{$x ||= 0; $x += 1}*3').should == [1,2,3]
    end
    
  end # described Ruby support
  
  
  def sequencer(input)
    Sequencer.new(input)
  end
  
  def sequence(input)
    if input.is_a? Sequencer
      sequener = input
    else
      sequener = sequencer(input)
    end
    sequence = []
    count = 0
    while value=sequener.next and count < SEQUENCE_COUNT_LIMIT
      sequence << value
      count += 1
    end
    if count == SEQUENCE_COUNT_LIMIT
      # this is for infinite loop prevention
      fail "#{input} output more than #{SEQUENCE_COUNT_LIMIT}" 
    end
    return sequence
  end
  
end