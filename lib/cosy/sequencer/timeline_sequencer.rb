module Cosy    

  class TimelineSequencer

    def initialize(options={})
      @options = options
      input = options[:input]
      if input.is_a? Sequencer
        @sequencer = input
      elsif input
        parse(input)
      end
      @sequences = {}
      @time = options.fetch :time, 0

      init()
    end

    def init
      @prev_pitches  = [Pitch.new(DEFAULT_PITCH_CLASS, DEFAULT_OCTAVE)]
      @prev_octave   = DEFAULT_OCTAVE
      @prev_velocity = DEFAULT_VELOCITY
      @prev_duration = DEFAULT_DURATION
      @octave_mode   = @options.fetch :octave_mode, DEFAULT_OCTAVE_MODE #deprecated
      @osc_host = @options.fetch :osc_host, 'localhost'
      @osc_port = @options.fetch :osc_port, 23456
      @duty = 0.99
    end

    def parse(cosy_syntax)
      @sequencer = Sequencer.new(cosy_syntax)
    end

    def render
      @timeline = Timeline.new
      while event = next_event
        case event

        when ParallelSequencer
          stop_time = @time
          event.each do |sequencer|
            renderer = self.class.new(clone_state(sequencer))
            renderer.render
            stop_time = renderer.time if renderer.time > stop_time
          end
          @time = stop_time
          next

        when NoteEvent
          pitches, velocity, duration = event.pitches, event.velocity, event.duration
          if duration >= 0
            notes(pitches, velocity, duration)
          else            
            rest(-duration)
          end
          next
          
        when OscAddress
          osc(event)
          next    
          
        when TypedValue
          value = event.value
          case event.type
          when :tempo
            tempo(value)
          when :program
            program(value)
          when :channel
            @channel = value-1 # I count channels starting from 1, but MIDIator starts from 0
          when :pitch_bend
            pitch_bend(value)
          when :cc
            cc(value[0],value[1])
          
          when :pitch
            @prev_pitches  = [value]
          when :octave
            @prev_octave   = value
          when :velocity
            @prev_velocity = value
          when :duration
            @prev_duration = value
          when :duty
            @duty = value
          end
          next
          
        when Chain
          first_value = event.first
          values = event[1..-1]
          case first_value
          when OscAddress
            osc(first_value, values)
            next    
          end
        end 
        
        STDERR.puts "Unsupported Event: #{event.inspect}"
      end

    end

    def timeline
      render if not @timeline
      return @timeline
    end


    # converts sequencer states to events
    def next_event
      event = @sequencer.next

      pitches  = @prev_pitches
      velocity = @prev_velocity
      duration = @prev_duration

      if event.is_a? Interval
        pitches = @prev_pitches.map{|pitch| pitch+event}

      elsif event.is_a? Chord and event.all?{|e| e.is_a? Pitch}
        pitches = event

      elsif event.is_a? Chain
        event.each do |param|
          case param
          when Pitch    then pitches = [param]
          when Chord    then pitches  = param
          when Velocity then velocity = param.value
          when Duration then duration = param.value
          else      
            first_value = event.first
            if first_value.is_a? Label
              label = first_value.value.downcase
              if label == OCTAVE_MODE_LABEL
                octave_mode = event[1]
                octave_mode = octave_mode.value if octave_mode.respond_to? :value # allow for labels as values
                octave_mode = octave_mode.downcase if octave_mode.respond_to? :downcase
                octave_mode = OCTAVE_MODE_VALUES[octave_mode]
                @octave_mode = octave_mode if octave_mode
                return next_event
              end
            end
            return event 
          end
        end

      elsif event.is_a? Pitch
        pitches = [event]

      elsif event.is_a? Velocity
        velocity = event.value

      elsif event.is_a? Duration
        duration = event.value  

      else
        return event 
      end

      pitch_values = []
      pitches.each do |pitch|
        if not pitch.has_octave?
          pitch.octave = @prev_octave
          if @octave_mode == :nearest
            prevval = @prev_pitches.first.value  # not sure what is reasonable for a chord, TODO match indexes?
            interval = prevval - pitch.value
            if interval >= 6
              pitch.octave += 1
            elsif interval < -6
              pitch.octave -= 1
            end
          end
        end
        @prev_octave = pitch.octave
        pitch_values << pitch.value
      end

      @prev_pitches = pitches
      @prev_velocity = velocity
      @prev_duration = duration.abs

      return NoteEvent.new(pitch_values,velocity,duration)
    end




    alias play render


    #################
    protected

    def time
      @time
    end

    def scheduler
      @scheduler
    end

    def start_time
      @start_time
    end


    #################
    private

    def clone_state(input)
      {
        :input => input,
        :parent => self,
        :time => @time,
        :channel => @channel,
        :tempo => @tempo,
        :osc_host => @osc_host,
        :osc_port => @osc_port
      }
    end

    def add_event(event)
      @timeline[@time] << event
    end

    def absolute_time
      @start_time + @time
    end

    def tempo(bpm)
      add_event Event::Tempo.new(bpm)
    end

    def program(program_number)
      add_event Event::ProgramChange.new(program_number, @channel)
    end

    def notes(pitches, velocity, duration)
      dur = duration * @duty
      pitches.each do |p|
        add_event Event::Note.new(p, velocity, dur, @channel)
      end
      @time += duration
    end

    def rest(duration)
      @time += duration
    end

    def cc(controller_number, value)
      add_event Event::ControlChange.new(controller_number, value, @channel)
    end

    def pitch_bend(value)
      add_event Event::PitchBend.new(value, @channel)
    end

    def osc(address, args)
      host = address.host || @osc_host
      port = address.port || @osc_port
      @osc_host, @osc_port = host, port
      add_event Event::OscMessage.new(host, port, address.path, *args)
    end

  end

end
