require File.dirname(__FILE__)+'/spec_helper'

describe Cosy::SequenceParser do

  before(:all) do
    @parser = SequenceParser.new
  end
  

  describe 'Atomic Values' do
    
    it 'should parse whitespace' do
      ['', ' ', '   ', "\t", "\n", "\r\f", "\n \t"].each do |whitespace|
        @parser.parse(whitespace).value.should == ''
      end
    end
    
    it 'should parse integers' do
      [0, 2, 789, -1].each do |int|
        @parser.parse(int).value.should == int
      end
    end
 
    it 'should parse floats' do
      [0.0, 2.5, 789.654321, -1.0001].each do |float|
        @parser.parse(float).value.should == float
      end
    end
    
    it 'should parse ratios' do
      [[1,2], [3,100], [-55,232]].each do |numerator,denominator|
        @parser.parse("#{numerator}/#{denominator}").value.should == numerator.to_f/denominator
      end
    end

    it 'should parse single-quoted strings' do
      ['a', 'a b c', '1'].each do |unquoted_string|
        @parser.parse("'#{unquoted_string}'").value.should == unquoted_string
      end
    end

    it 'should parse double-quoted strings' do
      ['a', 'a b c', '1'].each do |unquoted_string|
        @parser.parse('"' + unquoted_string + '"').value.should == unquoted_string
      end
    end
    
    it 'should parse strings with escaped quotes' do
      @parser.parse("'a b\\' c'").value.should == "a b' c"
      @parser.parse('"a b\\" c"').value.should == 'a b" c'
      # TODO: test this in sequenced values tests:
      # '"a b c" "a b\\" c"'
      # "'a b c' 'a b\\' c'"  
    end

    it 'should parse labels' do
      ['a', 'abc', '1'].each do |label|
        @parser.parse('#' + label).value.should == label
      end
      lambda{ @parser.parse('#') }.should raise_error
    end

    it 'should parse pitch symbols' do
      for note_name in 'A'..'G' do
        for octave in -1..9 do
          for accidental in [nil, '#', 'b'] do
            pitch = Pitch.new(note_name, accidental, nil)
            @parser.parse("#{note_name}#{accidental}").value.should == pitch
            
            pitch = Pitch.new(note_name, accidental, octave)
            @parser.parse("#{note_name}#{accidental}#{octave}").value.should == pitch
            
            note_name = note_name.downcase
            pitch = Pitch.new(note_name, accidental, octave)
            @parser.parse("#{note_name}#{accidental}#{octave}").value.should == pitch
          end
        end
      end
    end
    
    it 'should parse numeric pitches' do
      for note_number in [0, 50, 100, 127] do
        expected = Pitch.new(note_number)
        for pitch_prefix in %w{pit PIT pitch} do
          @parser.parse("#{pitch_prefix}#{note_number}").value.should == expected
        end
      end
    end
    
    it 'should parse pitch chords' do
      @parser.parse('[C]').value.should == [Pitch.new('C')]
      @parser.parse('[C E G]').value.should == [Pitch.new('C'), Pitch.new('E'), Pitch.new('G')]
      @parser.parse('[C4 E4 G4]').value.should == [Pitch.new('C',4), Pitch.new('E',4), Pitch.new('G',4)]
      @parser.parse('[C# Db4]').value.should == [Pitch.new('C#'), Pitch.new('C#',4)]
    end
    
    it 'should parse numeric chords' do
      @parser.parse('[1]').value.should == [1] 
      @parser.parse('[1 2 3]').value.should == [1,2,3]
      @parser.parse('[1.1]').value.should == [1.1]
      @parser.parse('[1.1 2.2 3.3]').value.should == [1.1, 2.2, 3.3] 
      @parser.parse('[-1]').value.should == [-1]
      @parser.parse('[-1 -2 -3]').value.should == [-1,-2,-3]
      @parser.parse('[-1.1]').value.should == [-1.1]
      @parser.parse('[1.1 -2.2 3.33333]').value.should == [1.1, -2.2, 3.33333] 
      @parser.parse('[1 2.2 -3 4/5]').value.should == [1, 2.2, -3, 4.0/5]
    end
    
    it 'should parser string chords' do
      @parser.parse('["abc" \'foo\']').value.should == ['abc','foo'] 
    end
    
    it 'should parse interval symbols' do
      for quality in ['M','m','p','P','maj','min','per','aug','dim',
                      'major','minor','perfect','augmented','diminished'] do
        for degree in 1..16 do
          for sign in [nil, '+', '-'] do
            if sign == '-'
              interval = Interval.new(quality,-degree)
            else
              interval = Interval.new(quality,degree)
            end
            @parser.parse("#{sign}#{quality}#{degree}").value.should == interval
          end
        end
      end
    end
    
    it 'should parse numeric intervals' do
      for semitones in -12..12 do
        interval = Interval.new(semitones)
        @parser.parse("i#{semitones}").value.should == interval
        @parser.parse("I#{semitones}").value.should == interval
      end
    end
    
    it 'should parse velocity symbols' do
      for intensity in [
        'ppp','pp','p','mp','mf','fo','ff','fff',
        'PPP','PP','P','MP','MF','FO','FF','FFF',
        'pianissimo','piano','mezzopiano','mezzo-piano',
        'mezzoforte','mezzo-forte','forte','fortissimo'
      ] do
        @parser.parse(intensity).value.should == Velocity.new(intensity)
      end
    end
    
    it 'should parse numeric velocities' do
      for velocity in [0, 50, 100, 127] do
        expected = Velocity.new(velocity)
        for velocity_prefix in %w{v V vel VEL velocity} do      
          @parser.parse("#{velocity_prefix}#{velocity}").value.should == expected
        end
      end
    end
    
    it 'should parse duration symbols' do
      for base_duration in [
        'w','h','q','ei','s','r','x',
        'W','H','Q','EI','S','R','X',
        'whole','half','quarter','eighth','sixteenth',
        'thirtysecond','thirty-second','sixtyfourth','sixty-fourth'
      ] do
        for multiplier in -2..2 do
          for modifier in [nil, 't', '.', '.t', 't.', '..', '...'] do
            duration = Duration.new(multiplier, base_duration, modifier)
            @parser.parse("#{multiplier}#{base_duration}#{modifier}").value.should == duration
            if multiplier == 1 then
              @parser.parse("#{base_duration}#{modifier}").value.should == duration
            elsif multiplier == -1 then
              @parser.parse("-#{base_duration}#{modifier}").value.should == duration
            end
          end
        end
      end
    end
    
    it 'should parse numerical durations' do
      for duration in [0, 50, 100, 5000, -25] do
        expected = Duration.new(duration)
        for duration_prefix in %w{dur DUR duration} do
          @parser.parse("#{duration_prefix}#{duration}").value.should == expected
        end
      end
    end
    
    it 'should parse ruby expressions' do
      ['1 + 2', "'}'", '"}"'].each do |ruby_expression|
        @parser.parse('{' + ruby_expression + '}').value.should == eval(ruby_expression)
      end
    end
    
  end # describing atomic values
  
  
  describe 'OSC Support' do
    
    it 'should parse osc paths' do
      ['/basic', '/1', '/1/a', '/a/1', '/nested/path/to/somewhere'].each do |path|
        osc_address = @parser.parse(path).value
        osc_address.path.should == path
      end
    end
    
    it 'should parse osc messages with a hostname' do
      osc_address = @parser.parse('osc://hostname.com/path/a').value
      osc_address.host.should == 'hostname.com'
      osc_address.port.should == nil
      osc_address.path.should == '/path/a'
    end

    it 'should parse osc messages with a hostname and port' do
      osc_address = @parser.parse('osc://hostname.com:8080/path/a').value
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