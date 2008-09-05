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
    (node.class != SubsequenceNode or node.children.size > 1)
end
def leaf? node
  node.terminal? or node.is_a? ChordNode
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
output = parse '(1 2 3)&4 ([C4 G4]:mf:q 60|70)*2.5'
output.start
# puts "VALS="
# while output.next? do
#   puts output.next
# end


print_tree output


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
