require File.dirname(__FILE__)+'/spec_helper'

describe Cosy::SequenceParser do

  before(:all) do
    @parser = SequenceParser.new
  end

  def parsed_value(input)
    @parser.parse(input).value
  end


  describe 'Basic Behavior' do

    it 'should parse whitespace' do
      ['', ' ', '   ', "\t", "\n", "\r\f", "\n \t"].each do |whitespace|
        parsed_value(whitespace).should == ''
      end
    end

    it 'should fail on invalid syntax' do
      for input in ['1.', '1 2)*3' 'asdf'] do
        lambda{ @parser.parse input }.should raise_error(RuntimeError)
      end
    end

  end


  describe 'Atomic Values' do
    it 'should parse integers' do
      [0, 2, 789, -1].each do |int|
        parsed_value(int).should == int
      end
    end

    it 'should parse floats' do
      [0.0, 2.5, 789.654321, -1.0001].each do |float|
        parsed_value(float).should == float
      end
    end

    it 'should parse ratios' do
      [[1,2], [3,100], [-55,232]].each do |numerator,denominator|
        parsed_value("#{numerator}/#{denominator}").should == numerator.to_f/denominator
      end
    end

    it 'should parse single-quoted strings' do
      ['a', 'a b c', '1'].each do |unquoted_string|
        parsed_value("'#{unquoted_string}'").should == unquoted_string
      end
    end

    it 'should parse double-quoted strings' do
      ['a', 'a b c', '1'].each do |unquoted_string|
        parsed_value('"' + unquoted_string + '"').should == unquoted_string
      end
    end

    it 'should parse strings with escaped quotes' do
      parsed_value("'\\''").should == "'"
      parsed_value('"\""').should == '"'
      parsed_value("'a b\\' c'").should == "a b' c"
      parsed_value('"a b\\" c"').should == 'a b" c'
    end

    it 'should parse labels' do # DEPRECATED
      ['a', 'abc', '1'].each do |label|
        parsed_value('#' + label).should == label
      end
      lambda{ @parser.parse('#') }.should raise_error
    end

    it 'should parse pitch symbols' do
      for note_name in 'A'..'G' do
        for octave in -1..9 do
          for accidental in [nil, '#', 'b'] do
            pitch = Pitch.new(note_name, accidental, nil)
            parsed_value("#{note_name}#{accidental}").should == pitch

            pitch = Pitch.new(note_name, accidental, octave)
            parsed_value("#{note_name}#{accidental}#{octave}").should == pitch

            note_name = note_name.downcase
            pitch = Pitch.new(note_name, accidental, octave)
            parsed_value("#{note_name}#{accidental}#{octave}").should == pitch
          end
        end
      end
    end

    it 'should parse numeric pitches' do
      for note_number in [0, 50, 100, 127] do
        expected = Pitch.new(note_number)
        for pitch_prefix in %w{pit PIT pitch} do
          parsed_value("#{pitch_prefix}#{note_number}").should == expected
        end
      end
    end

    it 'should parse pitch chords' do
      parsed_value('[C]').should == [Pitch.new('C')]
      parsed_value('[C E G]').should == [Pitch.new('C'), Pitch.new('E'), Pitch.new('G')]
      parsed_value('[C4 E4 G4]').should == [Pitch.new('C',4), Pitch.new('E',4), Pitch.new('G',4)]
      parsed_value('[C# Db4]').should == [Pitch.new('C#'), Pitch.new('C#',4)]
    end

    it 'should parse numeric chords' do
      parsed_value('[1]').should == [1] 
      parsed_value('[1 2 3]').should == [1,2,3]
      parsed_value('[1.1]').should == [1.1]
      parsed_value('[1.1 2.2 3.3]').should == [1.1, 2.2, 3.3] 
      parsed_value('[-1]').should == [-1]
      parsed_value('[-1 -2 -3]').should == [-1,-2,-3]
      parsed_value('[-1.1]').should == [-1.1]
      parsed_value('[1.1 -2.2 3.33333]').should == [1.1, -2.2, 3.33333] 
      parsed_value('[1 2.2 -3 4/5]').should == [1, 2.2, -3, 4.0/5]
    end

    it 'should parser string chords' do
      parsed_value('["abc" \'foo\']').should == ['abc','foo'] 
    end

    it 'should parse interval symbols' do
      qualities = ['M','m','p','P','maj','min','per','aug','dim']
      qualities += ['major','minor','perfect','augmented','diminished'] 
      for quality in qualities do
        for degree in 1..16 do
          for sign in [nil, '+', '-'] do
            if sign == '-'
              interval = Interval.new(quality,-degree)
            else
              interval = Interval.new(quality,degree)
            end
            parsed_value("#{sign}#{quality}#{degree}").should == interval
          end
        end
      end
    end

    it 'should parse numeric intervals' do
      for semitones in -12..12 do
        interval = Interval.new(semitones)
        parsed_value("i#{semitones}").should == interval
        parsed_value("I#{semitones}").should == interval
      end
    end

    it 'should parse velocity symbols' do
      intensities =  ['ppp','pp','p','mp','mf','fo','ff','fff']
      intensities += ['PPP','PP','P','MP','MF','FO','FF','FFF']
      intensities += ['pianissimo','piano','mezzopiano','mezzo-piano']
      intensities += ['mezzoforte','mezzo-forte','forte','fortissimo']
      for intensity in intensities
        parsed_value(intensity).should == Velocity.new(intensity)
      end
    end

    it 'should parse numeric velocities' do
      for velocity in [0, 50, 100, 127] do
        expected = Velocity.new(velocity)
        for velocity_prefix in %w{v V vel VEL velocity} do      
          parsed_value("#{velocity_prefix}#{velocity}").should == expected
        end
      end
    end

    it 'should parse duration symbols' do
      durations =  ['w','h','q','ei','s','r','x']
      durations += ['W','H','Q','EI','S','R','X']
      durations += ['whole','half','quarter','eighth','sixteenth']
      durations += ['thirtysecond','thirty-second','sixtyfourth','sixty-fourth']
      for base_duration in durations do
        for multiplier in -2..2 do
          for modifier in [nil, 't', '.', '.t', 't.', '..', '...', 't.t.t'] do
            duration = Duration.new(multiplier, base_duration, modifier)
            parsed_value("#{multiplier}#{base_duration}#{modifier}").should == duration
            if multiplier == 1 then
              parsed_value("#{base_duration}#{modifier}").should == duration
            elsif multiplier == -1 then
              parsed_value("-#{base_duration}#{modifier}").should == duration
            end
          end
        end
      end
    end   

    it 'should parse numerical durations' do
      for duration in [0, 50, 100, 5000, -25] do
        expected = Duration.new(duration)
        for duration_prefix in %w{dur DUR duration} do
          parsed_value("#{duration_prefix}#{duration}").should == expected
        end
      end
    end

    it 'should parse ruby expressions' do
      ['1 + 2', "'}'", '"}"'].each do |ruby_expression|
        parsed_value('{' + ruby_expression + '}').should == eval(ruby_expression)
      end
    end

  end # describing atomic values


  describe 'Keyword Assignments' do
    it 'should parse tempo assignments' do
      parsed_value('tempo=60').should == TypedValue.new(:tempo,60)
    end

    it 'should have more tests!'
  end


  describe 'Basic Sequences' do

    it 'should parse bare sequences' do
      tree = @parser.parse '0 1 2 3'
      tree.class.should == SequenceNode
      tree.children.length.should == 4
      tree.children.each_with_index do |item,index|
        item.value.should == index
      end
    end

    it 'should parse sequences wrapped in parentheses' do
      for seq in ['(1 2 3)', ' (1 2 3) ', '( 1 2 3 )', ' ( 1    2    3)    '] do
        tree = @parser.parse seq
        tree.children.length.should == 3
        tree.children.each_with_index do |item,index|
          item.value.should == index+1
        end
      end
    end

    it 'should parse sequences with partial parentheses' do
      for seq in ['1 (2 3)', '1 2  (3) ', '  (1 2 ) 3 '] do
        tree = @parser.parse seq
        count = 0
        tree.children.each do |item|
          if item.is_a? SequenceNode
            item.children.each do |subitem|
              count += 1
              subitem.value.should == count
            end 
          else
            count += 1
            item.value.should == count
          end
        end
        count.should == 3
      end
    end

    it 'should parse sequences of sequences' do
      for seq in ['(1 2 3) (4 5 6)', '( 1 2 ) ( 3 4 ) ( 5 6 )', '(1 (2 3) (4 (5) 6))'] do
        tree = @parser.parse seq
        count = 0
        tree.visit(lambda do |node|
          if node.terminal? then
            count += 1
            node.value.should == count
          end
          return !node.terminal?
        end)
        count.should == 6
      end
    end

    it 'should parse chord sequences' do
      tree = @parser.parse '[1] [2] [3]'
      tree.children.length.should == 3
      tree.children.each_with_index do |chord,index|
        chord.value.should == [index+1]
      end
      tree = @parser.parse '[1 2 3] [4 5 6] [7 8 9]'
      tree.children.length.should == 3
      tree.children.each_with_index do |chord,index|
        chord.value.should == [1+index*3, 2+index*3, 3+index*3]
      end
    end

  end # describing basic sequences


  describe 'Modified Sequences' do

    it 'should have tests that make assertions on the parse tree!'

    it 'should parse repeated sequences' do
      @parser.parse '1*2'
      @parser.parse '(1)*2'
      @parser.parse '(1 2)*2'
      @parser.parse '(1 2)*0'
      @parser.parse '(1 2)*-1'
    end

    it 'should parse repeated sequence with a ruby script modifier' do
      @parser.parse '(1 2)*{8/4}'
    end

    it 'should parse count limited sequences' do
      @parser.parse '1&4'
      @parser.parse '(1)&4'
      @parser.parse '(1 2)&4'
      @parser.parse '(1 2 3)&4'
    end

    it 'should parse fractionally repeated sequences' do
      @parser.parse '1*2.2'
      @parser.parse '(1)*2.20'
      @parser.parse '(1 2)*2.210'  
    end

    it 'should parse a sequence of repeated sequences' do
      @parser.parse '(1 2)*2 (3 4)*2.5 (6 7 8)*20'
      @parser.parse '(1 2)*2 (3 4) (6 7 8)*20'  
    end

    it 'should parse repeated chord sequences' do
      @parser.parse '[1]*2'
      @parser.parse '[1 2]*2'
      @parser.parse '[1]*2 [3]'
      @parser.parse '[1 2]*2 [3] [4 5 6]*3.2'
    end
    
    it 'should parse nested modified sequences' do
      @parser.parse '(1 2 (3 4)*3 5)*2'
      @parser.parse '(1 2 (3 4 5)&6)&7'
    end

    it 'should parse heterogenous modified sequences' do
      @parser.parse '(c4 5)*1.5'
      @parser.parse '[3 4]*3'
      @parser.parse '(c4 5)*1.5 [3 4]*3'
      @parser.parse '[fb3 c#+4]*3 (4.0*5 6*3)*2'
      @parser.parse '[fb3 c#+4]*3 ((4.0 5*5)*5 6*3)*2'
      @parser.parse '[2 c4] 3 (4.0 (6)*3)*2'
      @parser.parse '[2 c#+4] 3 (4.0 6*3)*2'
    end

  end


  describe 'Chains' do
    it 'should parse simple chains' do
      tree = @parser.parse '0:1:2:3'
      tree.class.should == ChainNode
      tree.children.length.should == 4
      tree.children.each_with_index do |item,index|
        item.value.should == index
      end
    end
    
    it 'should parse heterogenous chains' do
      @parser.parse '4:5:C4'
      @parser.parse 'C4:mf:q.'
      @parser.parse '[C4 E4]:fff'
      @parser.parse '(4 5):(6 7)'
    end
  end
  
  describe 'Other Constructs' do
    
    it 'should parse choices' do
      @parser.parse '4|5 | C4'
      @parser.parse 'C4|mf|q.'
      @parser.parse '[C4 E4]|fff'
      @parser.parse '(4 5)|(6 7)'
    end

    it 'should parse simple foreach loops' do
      @parser.parse '(1 2)@(3 4)'
      @parser.parse '(1 $ 2)@(3 4)'
    end

    it 'should parse chained foreach loops' do
      @parser.parse '(1 2)@(3 4)@(5 6)'
    end

    it 'should parse nested foreach loops' do
      @parser.parse '((1 2)@(3 4))@(5 6)'
      @parser.parse '((1 $ 2 $$)@(3 4 $))@(5 6)'
    end

    it 'should parse variable assignments and usages' do
      @parser.parse '$X=1 2 3 4; $X'
      @parser.parse '$X=1 2 3 4; $Y=5; $X $Y'   
    end

    it 'should parse labels' do # DEPRECATED
      @parser.parse '#label:5'
      @parser.parse '#1:c:mf'
      @parser.parse '#env:[1 250 1 500 0 250]'
    end

    it 'should parse parallel sequences' do
      @parser.parse 'a == b'
      @parser.parse 'a b c == c d e'
    end
  end


  describe 'OSC Support' do

    it 'should parse osc paths' do
      ['/basic', '/1', '/1/a', '/a/1', '/nested/path/to/somewhere'].each do |path|
        osc_address = parsed_value(path)
        osc_address.path.should == path
      end
    end

    it 'should parse osc messages with a hostname' do
      osc_address = parsed_value('osc://hostname.com/path/a')
      osc_address.host.should == 'hostname.com'
      osc_address.port.should == nil
      osc_address.path.should == '/path/a'
    end

    it 'should parse osc messages with a hostname and port' do
      osc_address = parsed_value('osc://hostname.com:8080/path/a')
      osc_address.host.should == 'hostname.com'
      osc_address.port.should == 8080
      osc_address.path.should == '/path/a'
    end    

    it 'should parse osc message chains with one value' do
      [100, -5.5, 'foo'].each do |value|
        osc_address = '/osc/addr'
        node = @parser.parse("#{osc_address}:#{value.inspect}")
        node.should be_instance_of(ChainNode)
        node.children.length.should == 2

        addr = node.children[0]
        addr.should be_instance_of(OscAddressNode)
        addr.path.value.should == osc_address

        arg = node.children[1]
        node_should_match_value arg,value
      end
    end

    it 'should parse osc message chains with multiple values' do
      [[100, -5.5], [1, 'foo'], ['a','b','c','d']].each do |values|
        osc_path = '/osc/addr'
        chain = osc_path + ':' + values.map{|v|v.inspect}.join(':')
        node = @parser.parse(chain)
        node.should be_instance_of(ChainNode)
        node.children.length.should == values.length + 1   # plus one for address

        addr = node.children[0]
        addr.value.path.should == osc_path
        values.each_with_index{ |val,i| node_should_match_value node.children[i+1],val }
      end
    end

  end # described OSC support

  def node_should_match_value node,value
    case value
    when Fixnum then node.should be_instance_of(IntNode)
    when Float  then node.should be_instance_of(FloatNode)
    when String then node.should be_instance_of(StringNode)
    end
    node.value.should == value
  end

end