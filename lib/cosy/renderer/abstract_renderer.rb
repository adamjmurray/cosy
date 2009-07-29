module Cosy    

  class AbstractRenderer
    
    def initialize(options={})
      @options = options
      input = options[:input]
      if input
        sequence(input)
      end
    end
    
    def sequence(cosy_syntax)
       @sequencer = Sequencer.new(:input => cosy_syntax)
       @timeline = @sequencer.timeline
    end
   
  end 

end
