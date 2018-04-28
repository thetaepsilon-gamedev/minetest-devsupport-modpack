## modns external loader

Using the files found in this directory,
it's possible to load "pure" modns components outside of minetest,
in standalone lua.
This makes it possible to run things like unit tests
without having to fire up a minetest server.

Things you can find in this directory:

* The init.lua script is a start-up script which sets up mtrequire in the global environment.
* The modns.sh shell script can be sourced using your shell
	to set up a "development environment" where lua scripts will have access to mtrequire.
* The exampledata directory is an example of configuration data
	whose contents shoud be copied to ~/.config/mt\_modns\_extdata.
	This directory contains data needed to load the pure parts of mods outside of minetest.



