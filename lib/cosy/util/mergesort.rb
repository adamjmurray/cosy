# This code borrowed from 'Moser' http://codesnippets.joyent.com/posts/show/1699

class Array
  
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