#              Cosy 
###  a COmpact Sequencing sYntax

<http://compusition.com/web/software/cosy>   


## Description ##

Cosy is a custom language for composing musical patterns and
general purpose sequencing. It strives to be as concise as possible, because
the less time we spend inputting our ideas into the computer, the more time
we have to make cool stuff.

  
## Author ##

Adam Murray (adam@compusition.com)


## Status ##

This project is immature. The syntax is not finalized, so I can't guarantee
I won't change things in a way that will break backward compatibility.

There are probably lots of bugs right now. 

Use at your own risk!


## Dependencies ##

Cosy depends on the following Ruby libraries:

*  treetop (which depends on polyglot)
*  midilib 
*  midiator
*  osc (optional)

To run Cosy you will need to install the gems for those libraries:

	gem install treetop
	gem install midilib
	gem install midiator

Note that midiator-0.3.0 or higher is needed for direct output on OS X

Optionally, if you want to use OSC support, you will also need to:

	gem install osc
	
	
## Running Cosy ##

Currently there are three main use cases for Cosy:

* Live playback of a MIDI sequence
* Generating MIDI files
* Running Cosy inside Max/MSP

An executable is provided to live playback and generation of MIDI files:

	bin/cosy
	
Run this script with no arguments for usage instructions.
Some example input files are provided in the examples folder. 

To run things inside Max/MSP you need the latest
version of my ajm.ruby object which I have not released yet. 
Check back soon.


## Documentation ##

The closest thing to documentation right now is the online preview at: 

<http://compusition.com/web/software/cosy/online>


# Future

TODOs:

* Allow independent control over the note duration and the inter-note-onset intervals
  (i.e. support staccato vs. legato)
* Numeric intervals (allow something like i2 and i7 instead of m2 and P5)
* A way to change the current octave, pitch, velocity, and duration without
  outputting anything
* Allow chains to be formed across scopes. For example, support:<br/>
  $melody=e:q d c:h; $melody:mp
* Documentation! And more examples.
* Release updated version of ajm.ruby and the Cosy Max/MSP object
* tick-rate generators, output faster than the sequencing rate, for doing things like CC LFOs
  and pitch bend envelopes
* a clean API for manipulating the sequencing tree on-the-fly as the sequencer is running
  (interactive control as well as self-modifying sequences)
* arpeggiators
* new node traversal behaviors, for example loops that go up/down instead of starting over when the
  last note is reached

I am considering making renderers for csound and lilypond at some point.

I'd like to explore using Cosy to sequence animations with Jitter and Processing.

