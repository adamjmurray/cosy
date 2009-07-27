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

*  treetop (for generating the parser)
*  midilib (for outputting midi files)
*  midiator (for interfacing with the midi driver)
*  gamelan (for scheduling live midi playback)
*  osc (for open sound control support)

To run Cosy you will need to install the gems for those libraries:

	gem install treetop
	gem install midilib
	gem install midiator
	gem install gamelan
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

* Methods for transposition, inversion, retrograde, inverting chords, etc
* Allow chains to be formed across scopes. For example, support:<br/>
  $melody=e:q d c:h; $melody:mp
* When chaining, I don't always want the pitch to advance when the
  rhythm advances (especially when rests are involved). 
  Introduce ^ as the mechanism for indicating that a chain should not advance 
  (c d e):(^h. -q)
* Documentation! And more examples.
* Release updated version of ajm.ruby and the Cosy Max/MSP object
* a clean API for manipulating the sequencing tree on-the-fly as the sequencer is running
  (interactive control as well as self-modifying sequences)
* arpeggiators
* pitches from summed intervals across independent parallel sequences a la Numerology
* new node traversal behaviors, for example loops that go up/down instead of starting over when the
  last note is reached

I am considering making renderers for csound and lilypond at some point.

I'd like to explore using Cosy to sequence animations with Jitter and Processing.

