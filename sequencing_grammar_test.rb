require 'sequencing_grammar_parser'
require 'pp'

# TODO: turn into some real unit tests

PARSER = SequencingGrammarParser.new

def parse input
  puts "PARSING: #{input}"
  output = PARSER.parse input
  if output
    puts 'success'
  else
    puts 'failure'
  end
  puts output
  puts
  return output
end


def important? node
  node.class != Treetop::Runtime::SyntaxNode and 
  (not defined? node.rest or node.rest.text_value.strip != '' or
     (defined? node.modifier and node.modifier.text_value.strip != ''))                                   
end
def leaf? node
  node.terminal? or node.is_a? NoteNode or node.is_a? RubyNode
end
def visit_important_nodes node, enter, exit=nil
  node.visit(
  lambda do |node| # enter
    if important? node then
      enter.call node
    end
    not leaf? node
  end,
  lambda do |node| # exit
    exit.call node if important? node
  end
  )  
end

def print_tree node
  depth=0
  visit_important_nodes(node,
  lambda do |node| # enter
#     if node.class == ChoiceNode then
#       puts 'HERE ' + node.text_value + ' ' 
# #     node.elements.each {|e| print e.class.to_s + ' // ' + e.text_value + ' ??? ' + (e.text_value == '').to_s }
#       puts node.first.text_value
#       puts node.rest.text_value, node.rest.text_value.strip != ''
#     end
    
    depth.times {print "    "}
    print node.class, ' ' 
    puts node.text_value
    depth += 1 if not leaf? node
  end,
  lambda do |node| # exit
    depth -= 1
  end
  )  
end




# parse '(1)'
# parse '(1)*5'

# parse '"a b c" "a b\\" c"'
# parse "'a b c' 'a b\\' c'"
# 
# parse "{1 + 2} {'}'} {\"}\"}"
# 
# parse '[2 c4] 3 (4.0 (6)*3)*2'
# parse '[2 c#+4] 3 (4.0 6*3)*2'
# parse '[fb3 c#+4]*3 (4.0*5 6*3)*2'
# output = parse '[fb3 c#+4]*3 ((4.0 5*5)*5 6*3)*2'
# output.start
# puts "VALS="
# while output.next? do
#  puts output.next.inspect
# end
# 
# output = parse '(c4 5)*1.5 [3 4]*3'
# output.start
# puts "VALS="
# while output.next? do
#   puts output.next.inspect
# end
# 
# output = parse '{1 + 2} "a"'
# output.start
# puts "VALS="
# while output.next? do
#   puts output.next
# end
# 
# 
output = parse '(1 2 3)&4 ([C4 G4]:mf:q (C4:f:e | G4:f:s*2)) * 2.5'
#output = parse '(1 2 3)&4'
PARSER.print_tree output
puts "\n"

# output = parse '(1 2)&4'
# output.start
# puts "VALS="
# while output.next? do
#   puts output.next
# end



# 
#     
#     output = parse '(1 2)*0'
#     while output.next? do
#       puts output.next
#     end
#     
# 
# 
# 
