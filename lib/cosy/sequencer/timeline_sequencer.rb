module Cosy    

  class TimelineSequencer

    def initialize(options={})
      @sequencer     = options.fetch :sequencer, Sequencer.new(options[:input])
      @timeline      = options.fetch :timeline, Timeline.new
      @time          = options.fetch :time, 0
      @pitches       = options.fetch :pitches, [Pitch.new(DEFAULT_PITCH_CLASS, DEFAULT_OCTAVE)]
      @octave        = options.fetch :octave, DEFAULT_OCTAVE
      @velocity      = options.fetch :velocity, DEFAULT_VELOCITY
      @duration      = options.fetch :duration, DEFAULT_DURATION
      @duty          = options.fetch :duty, 0.99
      @channel       = options.fetch :channel, 0
      @octave_mode   = options.fetch :octave_mode, DEFAULT_OCTAVE_MODE #deprecated
      @osc_host      = options.fetch :osc_host, 'localhost'
      @osc_port      = options.fetch :osc_port, 23456
      @parent        = options[:parent]
    end

    def render
      if not @rendered
        while event = next_event
          case event

          when ParallelSequencer
            stop_time = @time
            event.each do |subsequencer|
              timeline_seq = clone(subsequencer)
              timeline_seq.render
              stop_time = timeline_seq.time if timeline_seq.time > stop_time
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
              @pitches  = [value]
            when :octave
              @octave   = value
            when :velocity
              @velocity = value
            when :duration
              @duration = value
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
        @rendered = true
      end 
      return @timeline
    end

    alias timeline render


    # converts sequencer states to events
    def next_event
      event = @sequencer.next

      pitches  = @pitches
      velocity = @velocity
      duration = @duration

      if event.is_a? Interval
        pitches = @pitches.map{|pitch| pitch+event}

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
          pitch.octave = @octave
          if @octave_mode == :nearest
            prevval = @pitches.first.value  # not sure what is reasonable for a chord, TODO match indexes?
            interval = prevval - pitch.value
            if interval >= 6
              pitch.octave += 1
            elsif interval < -6
              pitch.octave -= 1
            end
          end
        end
        @octave = pitch.octave
        pitch_values << pitch.value
      end

      @pitches = pitches
      @velocity = velocity
      @duration = duration.abs

      return NoteEvent.new(pitch_values,velocity,duration)
    end

    alias play render

    #################
    protected

    def time
      @time
    end


    #################
    private

    def clone(subsequencer)
      self.class.new({
        :parent => self,
        :sequencer => subsequencer,
        :timeline => @timeline,
        :time => @time,
        :pitches => @pitches,
        :octave => @octave,
        :velocity => @velocity,
        :duration => @duration,
        :channel => @channel,
        :octave_mode => @octave_mode,
        :osc_host => @osc_host,
        :osc_port => @osc_port
      })
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
