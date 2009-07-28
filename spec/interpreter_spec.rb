require File.dirname(__FILE__)+'/spec_helper'

describe Cosy::Interpreter do

  # Run the interpreter to create a stream of states
  def interpret(input)
    if input.is_a? Interpreter
      interpreter = input
    else
      interpreter = Interpreter.new(input)
    end
    sequence = []
    count = 0
    while value=interpreter.next and count < SEQUENCE_COUNT_LIMIT
      sequence << value
      count += 1
    end
    if count == SEQUENCE_COUNT_LIMIT
      # this is for infinite loop prevention
      fail "#{input} output more than #{SEQUENCE_COUNT_LIMIT}" 
    end
    return sequence
  end


  it 'should have infinite loop prevention in this spec' do
    lambda{ interpret "1*#{SEQUENCE_COUNT_LIMIT+1}" }.should raise_error(RuntimeError)
  end  


  describe 'Sequences' do
    it 'should interpret a single element' do
      interpret('1').should == [1]
    end

    it 'should interpret a simple sequence' do
      interpret('1 2').should == [1, 2]
    end

    it 'should interpret a single chord' do
      interpret('[1 2 3]').should == [[1,2,3]]
    end

    it 'should interpet a sequence of chords' do
      interpret('[1 2] [3 4] [5 6 7]').should == [[1,2],[3,4],[5,6,7]]
    end

    it 'should interpret a mixed chord & primitive sequence' do
      interpret('1 [2 3] 4 [5 6]').should == [1, [2,3], 4, [5,6]]
    end
  end  


  describe 'Repetitions' do
    it 'should interpret basic repeated sequences' do
      interpret('1*2').should == [1,1]
      interpret('(1)*3').should == [1,1,1]
      interpret('1*0').should == []         
      interpret('1*-1').should == []    
      interpret('(1 2)*1').should == [1,2]   
      interpret('(1 2)*2').should == [1,2,1,2]
      interpret('(1 2)*0').should == []         
      interpret('(1 2)*-1').should == []         
    end

    it 'should interpret heterogenous repeated sequences' do
      interpret('0 1*3 (2 3)*2 [4 5]*3').should == [0,1,1,1,2,3,2,3,[4,5],[4,5],[4,5]]
    end

    it 'should interpret ruby expression repetitions' do
      interpret('(1 2)*{8/4}').should == [1,2,1,2]
      interpret('1*{2**2}').should == [1,1,1,1]
    end

    it 'should interpret fractional repetitions' do
      interpret('(1 2)*2.5').should == [1,2,1,2,1]
      interpret('(1 2)*5/2').should == [1,2,1,2,1]  
      interpret('(1 2 3)*1.3').should == [1,2,3,1]   
      interpret('(1 2 3)*1.5').should == [1,2,3,1,2]
      interpret('(1 2 3)*4/3').should == [1,2,3,1]
    end

    it 'should interpret nested repetitions' do
      interpret('(1 (2 3)*2)*2').should == [1,2,3,2,3,1,2,3,2,3]
    end  
  end

  describe 'Count Limits' do

    it 'should interpret count limits' do
      interpret('1&4').should == [1,1,1,1]
      interpret('(1)&4').should == [1,1,1,1]
      interpret('1&8/2').should == [1,1,1,1]
      interpret('1&0').should == []     
      interpret('1&-1').should == []           
      interpret('(1 2)&4').should == [1,2,1,2]
      interpret('(1 2)&5').should == [1,2,1,2,1]
      interpret('(1 2 3)&4').should == [1,2,3,1]
      interpret('(1 2 3)&2').should == [1,2]
      interpret('(1 2)&0').should == []     
      interpret('(1 2)&-1').should == []             
    end

    it 'should interpret ruby expression count limits' do
      interpret('(1 2)&{8/4}').should == [1,2]
      interpret('1&{2**2}').should == [1,1,1,1]
      interpret('(1 2 3)&{2**2}').should == [1,2,3,1]     
    end

    it 'should interpret nested count limits' do
      interpret('(1 (2 3)&3)&9').should == [1,2,3,2,1,2,3,2,1]
    end

    it 'should interpret reptitions inside count limits' do
      interpret('(1 (2 3)*3)&9').should ==  [1,2,3,2,3,2,3,1,2]
    end
  end

  describe 'Ruby Support' do
    it 'should re-evaluate Ruby values for numeric parameters' do
      $x = nil
      interpret('pitch{$x ||= 0; $x += 1}*3').should == [1,2,3]
      $x = nil
      interpret('i{$x ||= 0; $x += 1}*3').should == [1,2,3]
      $x = nil
      interpret('vel{$x ||= 0; $x += 1}*3').should == [1,2,3]
      $x = nil
      interpret('duration{$x ||= 0; $x += 1}*3').should == [1,2,3]
    end
  end 

end