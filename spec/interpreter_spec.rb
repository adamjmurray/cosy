require File.dirname(__FILE__)+'/spec_helper'
require 'set'

describe Cosy::Interpreter do

  # Run the interpreter to create a stream of states
  def interpret(input)
    to_sequence(Interpreter.new(input))
  end

  def to_sequence(interpreter)
    sequence = []
    count = 0
    while value=interpreter.next_atom and count < SEQUENCE_COUNT_LIMIT
      sequence << value
      count += 1
    end
    if count == SEQUENCE_COUNT_LIMIT
      # this is for infinite loop prevention
      fail "#{interpreter.input} output more than #{SEQUENCE_COUNT_LIMIT}" 
    end
    return sequence
  end


  it 'should have infinite loop prevention in this spec' do
    lambda{ interpret("1*#{SEQUENCE_COUNT_LIMIT+1}") }.should raise_error(RuntimeError)
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

    it 'should interpret a sequence of strings' do
      interpret("'a' 'b' 'c'").should == ['a','b','c']
      interpret('"a" "b" "c"').should == ['a','b','c']
    end

    it 'should interpret a sequence of strings with escaped quotes' do
      # checks to make sure we can sequence things like
      # "nested \\"quoted\\" strings"  and  'this test\'s confusing!'
      interpret('\'"\' "\'"').should == ['"',"'"]
      interpret("'\"' \"'\"").should == ['"',"'"]
      interpret('"a b c" "a b\\" c"').should == ['a b c', 'a b" c']
      interpret("'a b c' 'a b\\' c'").should == ['a b c', "a b' c"]
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


  describe 'Pitches and Chords' do
    it 'should interpret a pitch sequence' do
      interpret('C4 F4 G4 Ab4 F#4').should == [60,65,67,68,66]       
      interpret('c4 f4 g4 ab4 F#4').should == [60,65,67,68,66] 
      interpret('C F G Ab F#').should == [0,5,7,8,6]
      interpret('c f g ab f#').should == [0,5,7,8,6]       
    end

    it 'should interpret a numeric pitch sequence' do
      interpret('pit60 pit65 pit67 pit68').should == [60,65,67,68]
      interpret('pit60.0 pit65.5').should == [60.0,65.5]
      interpret('pit100/4').should == [25.0]  
      interpret('pit{4**2}').should == [16]
    end

    it 'should interpret repeated pitches' do
      interpret('C4 F4*3 (G4 Ab4)*2').should == [60,65,65,65,67,68,67,68]       
    end

    it 'should interpret chords' do
      interpret('[C4 F4 G4 Ab4]').should == [[60,65,67,68]] 
    end

    it 'should intepret a chord sequence' do
      interpret('[C4 F4] [G4 Ab4]').should == [[60,65],[67,68]]
    end

    it 'should interpret repeated chords' do
      interpret('[C4 F4]*2').should == [[60,65],[60,65]]
      interpret('([C4 F4])*2').should == [[60,65],[60,65]]
    end
  end


  describe 'Rhythms' do
    it 'should interpret rhythmic symbols' do
      expected = [W, H, Q, EI, S, R, X]
      interpret('w h q ei s r x').should == expected
      interpret('W H Q EI S R X').should == expected
      interpret('whole half quarter eighth sixteenth thirtysecond sixtyfourth').should == expected
      interpret('thirty-second sixty-fourth').should == expected.last(2)
      interpret('w. h. q. ei. s. r. x.').should == expected.map{|dur| dur*1.5}
      interpret('wt ht qt eit st rt xt').should == expected.map{|dur| dur*2/3}
    end

    it 'should interpret numeric rhythms' do
      interpret('dur100 dur200 dur300').should == [100, 200, 300]
      interpret('dur100.5 dur200.33 dur-30.0').should == [100.5, 200.33, -30.0]
      interpret('dur5/4').should == [5.0/4]
      interpret('dur{5*4}').should == [20]
    end

    it 'should interpret modified rhythms' do
      base_expect = DURATION.values
      base_input = DURATION.keys
      tests = { 
        1 => '',
        1.5 => '.',
        1.5**2 => '.'*2,
        1.5**3 => '.'*3,
        2.0/3 => 't',
        2.0/3 * 1.5 => 't.',
        1.5 * 2.0/3 => '.t',
        1.5 * 2.0/3 => '.t',
        4.0/5 => ['4/5','']  # quintuplets
      }
      tests.each_pair do |multiplier,modifier|
        premod = ''
        if modifier.is_a? Array
          premod = modifier[0]
          modifier = modifier[1]
        end
        expected = base_expect.map{|val| val*multiplier}
        input = base_input.map{|val|premod+val+modifier}.join(' ')
        interpret(input).should == expected
      end
    end
  end


  describe 'Velocities' do
    it 'should interpret velocity symbols' do
      interpret('ppp pp p mp mf fo ff fff').should == [PPP, PP, P, MP, MF, FO, FF, FFF]
      interpret('pianissimo piano mezzopiano mezzo-piano mezzoforte mezzo-forte forte fortissimo'
      ).should == [PP, P, MP, MP, MF, MF, FO, FF]
    end

    it 'should interpret numeric velocities' do
      interpret('v1 v2 v3 v4').should == [1, 2, 3, 4]
      interpret('v1.1 v2.02 v3.0').should == [1.1, 2.02, 3.0]
      interpret('v10/3').should == [10.0/3]
      interpret('v{9-2}').should == [7]
    end
  end


  describe 'Chains' do
    it 'should interpret simple chains' do
      interpret('1:2').should == [[1,2]]
      interpret('1:2:3').should == [[1,2,3]]
    end

    it 'should interpret a sequence of simple chains' do
      interpret('1:2 3:4:5').should == [[1,2],[3,4,5]]
    end

    it 'should interpret chained sequences' do    
      interpret('c4:(s ei) f4').should == [[60,120],[60,240],65]
    end

    it 'should interpret complex chains of the same length' do
      interpret('(1 2):(3 4)').should == [[1,3],[2,4]]
    end

    it 'should interpret complex chains of the same length within a sequence' do
      interpret('(1 2):(3 4) 5').should == [[1,3],[2,4],5]
    end

    it 'should interpret complex chains of different lengths' do
      interpret('(1 2):(3 4 5)').should == [[1,3],[2,4],[1,5]]
      interpret('(1 2):(3 4 5):(6 7 8 9)').should == [[1,3,6],[2,4,7],[1,5,8],[2,3,9]]
    end

    it 'should interpret complex chains with repetition' do
      interpret('(1 2)*2:(3 4 5):(6 7 8)').should == [[1,3,6],[2,4,7],[1,5,8],[2,3,6]]
      interpret('(1 2):(3 4 5)&4:(6 7 8)').should == [[1,3,6],[2,4,7],[1,5,8],[2,3,6]]
    end

    it 'should interpret nested chains' do
      interpret('(1:2 3:4):(5 6 7)').should == [ [[1,2],5],[[3,4],6],[[1,2],7] ]
    end
  end


  describe 'Choices' do
    it 'should interpret a choice' do
      interpreter = Interpreter.new '(1|2|3)'
      seen_values = Set.new
      100.times do
        interpreter.restart
        seen_values << interpreter.next_atom
        interpreter.next_atom.should == nil
      end
      # may occasionally fail, since choices are random:
      seen_values.should == [1,2,3].to_set
    end

    it 'should interpret a choice of pitches' do
      interpreter = Interpreter.new '( C4 | E4 | G4 )'
      seen_values = Set.new
      100.times do
        interpreter.restart
        seen_values << interpreter.next_atom
        interpreter.next_atom.should == nil
      end
      # may occasionally fail, since choices are random:
      seen_values.should == [60,64,67].to_set  
    end

    it 'should interpret a choice of chords' do
      interpreter = Interpreter.new '([C4 G4]| [D4 G4] | G4)'
      seen_values = Set.new
      100.times do
        interpreter.restart
        seen_values << interpreter.next_atom
        interpreter.next_atom.should == nil
      end
      # may occasionally fail, since choices are random:
      seen_values.should == [[60,67],[62,67],67].to_set  
    end

    it 'should interpret a sequence of choices' do
      interpreter = Interpreter.new '(1 | 2 | 3) (C4|E4|G4)'
      seen_values = Set.new
      seen1 = Set.new
      seen2 = Set.new
      200.times do |n|
        interpreter.restart
        n = interpreter.next_atom
        seen1 << n
        seen_values << n
        n = interpreter.next_atom
        seen2 << n
        seen_values << n
        interpreter.next_atom.should == nil
      end
      # may occasionally fail, since choices are random
      expected1 = [1,2,3].to_set
      expected2 = [60,64,67].to_set
      seen1.should == expected1
      seen2.should == expected2
      seen_values.should == (expected1 + expected2)
    end

  end

  describe 'Foreach Loops' do
    it 'should interpret basic foreach loops' do
      interpret('(1 2)@($ 3)').should == [1,3,2,3]
      interpret('(1 2)@($ 3 $)').should == [1,3,1,2,3,2]
      interpret('(1 2 1)@($ 3 $)').should == [1,3,1,2,3,2,1,3,1]
    end

    it 'should interpret foreach loops in sequence' do
      interpret('0 (1 2)@($ 3) 0').should == [0,1,3,2,3,0]
      interpret('0 (1 2)@($ 3 $) 0').should == [0,1,3,1,2,3,2,0]
      interpret('0 (1 2 1)@($ 3 $) 0').should == [0,1,3,1,2,3,2,1,3,1,0]
    end

    it 'should interpret nested foreach loops' do
      interpret('(1 2)@(3 4)@($$ $ 5)').should == [1,3,5,1,4,5,2,3,5,2,4,5]
      interpret('(1 2)@((3 4)@($$ $ 5))').should == [1,3,5,1,4,5,2,3,5,2,4,5]
    end

    it 'should interpret foreach loops with modified subsequences' do
      interpret('(1 (2 3)&3)@($ 9)').should == [1,9,2,9,3,9,2,9]
      interpret('(1 (2 3)&3)@($*2 9)').should == [1,1,9,2,2,9,3,3,9,2,2,9]
    end

    it 'should interpret repeated & count limited foreach loops' do
      interpret('((1 2)@($ 3))*2').should == [1,3,2,3,1,3,2,3]
      interpret('((1 2)@($ 3))&7').should == [1,3,2,3,1,3,2]
    end
  end


  describe 'Variables' do
    it 'should interpret variable assignments and usages' do
      interpret('$X=1 2 3 4; $X').should == [1,2,3,4]
      interpret('$X=1 2 3 4; $Y=5; $X $Y').should == [1,2,3,4,5]
      interpret('$X=1 2 3 4; $Y=5; $Z=[6 7]; $X $Y $Z').should == [1,2,3,4,5,[6,7]]
      interpret('$X=1 2 3 4; $Y=5; $Z=[6 7]; $X $Y:100 $Z').should == [1,2,3,4,[5,100],[6,7]]
    end    
  end


  describe 'Ruby Support' do
    it 'should interpret ruby expressions' do
      interpret('1 {3+4} 2').should == [1,7,2]
    end

    it 'should interpret ruby commands' do
      $X = 0
      interpret('1 {{$X=25}} 2').should == [1,2]
      $X.should == 25
    end

    it 'should interpret ruby expressions that access the parse tree' do
      interpret('1 {node.parent.children[0].value} 2').should == [1,1,2]
    end

    it 'should interpret commands that alter the structure of the parse tree' do
      interpret('1 2 {{node.parent.children.reverse!}} 3').should == [1,2,1]
    end

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


  describe 'Interpreter Internals' do
    it 'should support restarting' do
      interpreter = Interpreter.new('1 2 3')
      to_sequence(interpreter).should == [1,2,3]
      interpreter.next_atom.should == nil
      to_sequence(interpreter).should == []
      interpreter.restart
      to_sequence(interpreter).should == [1,2,3]
    end

    it 'should support restarting after partial interpretation' do
      interpreter = Interpreter.new('1 (2 3)*2 (5 6):(7 8)')
      seq = []
      4.times{ seq << interpreter.next_atom }
      interpreter.restart
      6.times{ seq << interpreter.next_atom }
      interpreter.restart
      seq << interpreter.next_atom
      seq.should == [1,2,3,2,  1,2,3,2,3,[5,7],  1]
    end
  end

end