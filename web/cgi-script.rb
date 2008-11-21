#!/usr/bin/env ruby
begin

# ensure my lib dir is at front of search path
$LOAD_PATH[0,0] = File.join(File.dirname(__FILE__), 'lib')

require 'cosy/renderer/midi_file_renderer.rb'
module Cosy
  class RubyNode
    def value(context)
      raise 'embedded Ruby not allowed online'
    end
  end
  class CommandNode
    def value(context)
      raise 'embedded Ruby not allowed online'
    end
  end
end

require 'tempfile'
require 'cgi'
cgi = CGI.new 
$input = cgi['i'][0]
raise 'Input is required' if $input.nil? or $input.strip.length==0
$output_type = cgi['o'][0]

tempfile = Tempfile.new("ajm_cosy_temp") 
outfile =  tempfile.path 
tempfile.close

renderer = Cosy::MidiRenderer.new
renderer.render $input, outfile

if $output_type=='embed'
  print "Content-type: audio/midi\r\n" 
else
  print "Content-type: application/octet-stream\r\n" 
  print "Content-Disposition: attachment; filename=\"cosy.mid\"\r\n"
end
print "Content-Length: #{File.size(outfile)}\r\n"
print "Expires: 0\r\n\r\n"   

File.open(outfile) { |file| print file.read } 

rescue Exception
  print "Content-type: text/html\r\n\r\n" 
  print $!.to_s.sub("\n", "<br/>")
end
