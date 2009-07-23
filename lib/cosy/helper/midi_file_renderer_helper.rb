require 'midilib'

# First we need to add some API infrastructure:
class Array
  # This code borrowed from 'Moser' http://codesnippets.joyent.com/posts/show/1699
  
  # A stable sorting algorithm that maintains the relative order of equal elements
  def mergesort(&cmp)
    if cmp == nil
      cmp = lambda { |a, b| a <=> b }
    end
    if size <= 1
      self.dup
    else
      halves = split.map{ |half|
        half.mergesort(&cmp)
      }
      merge(*halves, &cmp)
    end
  end

  protected
  def split
    n = (length / 2).floor - 1
    [self[0..n], self[n+1..-1]]
  end

  def merge(first, second, &predicate)
    result = []
    until first.empty? || second.empty?
      if predicate.call(first.first, second.first) <= 0
        result << first.shift
      else
        result << second.shift
      end 
    end
    result.concat(first).concat(second)
  end
end

module MIDI
  class Track
    def insert(event, time) 
      event.time_from_start = time
      events << event
      return event
    end

    # Redefine recalc method to use a stable mergesort instead of the default sort
    # (otherwise this method should be the same as the original source,
    #  which was true as of Midilib 1.0.0)
    def recalc_delta_from_times(starting_at=0, list=@events)
      prev_time_from_start = 0
      # We need to sort the sublist. sublist.sort! does not do what we want.
      list[starting_at .. -1] = list[starting_at .. -1].mergesort { | e1, e2 |
        e1.time_from_start <=> e2.time_from_start
      }
      list[starting_at .. -1].each { | e |
        e.delta_time = e.time_from_start - prev_time_from_start
        prev_time_from_start = e.time_from_start
      }
    end
  end

  class Sequence
    def create_track(name=nil)
      track = MIDI::Track.new(self)
      track.name = name if name
      tracks << track
      return track  
    end
  end
end
