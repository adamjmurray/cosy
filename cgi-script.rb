#!/usr/bin/env ruby
begin

# ensure my lib dir is at front of search path
$LOAD_PATH[0,0] = File.join(File.dirname(__FILE__), 'lib')

require 'cosy/renderer/midi_file.rb'
require 'tempfile'
require 'cgi'
cgi = CGI.new 

tempfile = Tempfile.new("ajm_cosy_temp") 
outfile =  tempfile.path 
tempfile.close

renderer = Cosy::MidiRenderer.new
renderer.render cgi['cosy'], outfile

print "Content-type: audio/midi\r\n" 
print "Expires: 0\r\n\r\n" 

File.open(outfile) { |file| print file.read } 

rescue Exception
  print "Content-type: text/html\r\n\r\n" 
  print $!
end
