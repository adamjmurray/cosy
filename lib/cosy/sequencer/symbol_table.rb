module Cosy
  
  # A symbol table for managing variable definitions.
  # Provides a Hash-based mechanism for basic variable definitions, as
  # well as a "magic" variable stack for variables names consisting only of dollar signs ('$').
  # A basic scoping mechanism is provided by a simple parent/child relationsip.
  class SymbolTable < Hash
    
    # Construct a new SymbolTable, optionally providing a parent scope.
    def initialize(parent=nil)
      @magic = []
      @parent = parent
    end
    
    alias set []=
    def []=(name,value)
      if name =~ /^[$]*$/
        raise 'Cannot define a magic variable (#{name}) with []=. Use push_magic_variable().'
      end
      set(name,value)
    end
    
    # Define a new magic variable, which can be looked up as '$'.
    # Previously defined magic variables will have an addition '$' appended to their
    # name (so an existing '$' variable becomes '$$')
    def push_magic_variable(value)
      @magic.push(value)
    end
  
    # Undefine a magic variable, undoing the effect of the last push_magic_variable() call.
    def pop_magic_variable()
      @magic.pop
    end
  
    # Lookup a variable definition, taking into account the rules for magic variables.
    # If the variable is not found in this scope, and a parent scope exists, the parent
    # scope will be searched for a definition.
    def lookup(name)
      if name =~ /^[$]*$/
        # n dollar signs retrieves the nth value from the top of the @magic stack
        value = @magic[-name.length]
        if not value and @magic.length > 0
          # eat as many '$' as there are @magic entries in this scope
          name = name[0...-@magic.length]
        end  
      else
        value = self[name]
      end
      
      if not value and @parent
        value = @parent.lookup(name)
      end
      return value
    end
  end
  
end