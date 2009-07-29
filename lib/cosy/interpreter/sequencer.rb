module Cosy    

  class Sequencer

    # Construct a new Sequencer. The only required option is :input
    def initialize(options={})
      @interpreter   = options.fetch :interpreter, Interpreter.new(options[:input])
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

    # Convert the input String to a Timeline
    def timeline
      if not @rendered
        while event = next_event
          case event

          when ParallelInterpreter
            stop_time = @time
            event.each do |intepreter|
              timeline_seq = clone(intepreter)
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
              @channel = value-1 # I count channels starting from 1, but MIDIator starts from 0, TODO: let's not make this adjustment until the last moment in the renderer
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

    alias render timeline


    # converts atoms emmitted by the interpreter into events
    def next_event
      atom = @interpreter.next_atom

      pitches  = @pitches
      velocity = @velocity
      duration = @duration

      case atom
      when Pitch
        pitches = [atom]

      when Chord
        pitches = atom.find_all{|elem| elem.is_a? Pitch}

      when Interval
        pitches = @pitches.map{|pitch| pitch+atom}

      when Velocity
        velocity = atom.value

      when Duration
        duration = atom.value

      when Chain
        atom.each do |elem|
          case elem
          when Pitch    then pitches = [elem]
          when Chord    then pitches  = elem
          when Velocity then velocity = elem.value
          when Duration then duration = elem.value
          else return atom 
          end
        end

      else return atom 
      end

      pitch_values = []
      pitches.each do |pitch|
        pitch.octave = @octave if not pitch.has_octave?
        @octave = pitch.octave
        pitch_values << pitch.value
      end

      @pitches = pitches
      @velocity = velocity
      @duration = duration.abs

      return NoteEvent.new(pitch_values,velocity,duration)
    end


    #################
    protected

    def time
      @time
    end
    

    #################
    private

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

    def clone(interpreter)
      options = {
        :parent => self,
        :interpreter => interpreter,
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
      }
      self.class.new(options)
    end

  end
end
