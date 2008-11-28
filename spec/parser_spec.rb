require File.dirname(__FILE__)+'/spec_helper'

describe Cosy::SequenceParser do

  before(:all) do
    @parser = SequenceParser.new
  end
  

  describe '(atomic values)' do
    
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
      ['a', 'a b', '1'].each do |unquoted_string|
        @parser.parse("'#{unquoted_string}'").value.should == unquoted_string
      end
    end

    it 'should parse double-quoted strings' do
      ['a', 'a b', '1'].each do |unquoted_string|
        @parser.parse('"' + unquoted_string + '"').value.should == unquoted_string
      end
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
    
    it 'should parse pitch chords' do
      @parser.parse('[C E G]').value.should == [Pitch.new('C'), Pitch.new('E'), Pitch.new('G')]
    end
    
    it 'should parse numeric chords' do
      @parser.parse('[1 2.2 -3 4/5]').value.should == [1, 2.2, -3, 4.0/5]
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
            end  
          end
        end
      end
    end

    it 'should parse ruby expressions' do
      ['1 + 2', "'}'", '"}"'].each do |ruby_expression|
        @parser.parse('{' + ruby_expression + '}').value.should == eval(ruby_expression)
      end
    end
    
  end # describing primitive value behaviors
  
end