#charset "us-ascii"
//
// sample.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// This is a very simple demonstration "game" for the debugToolKit library.
//
// It can be compiled via the included makefile with
//
//	# t3make -f makefile.t3m
//
// ...or the equivalent, depending on what TADS development environment
// you're using.
//
// This "game" is distributed under the MIT License, see LICENSE.txt
// for details.
//
#include <adv3.h>
#include <en_us.h>

#include "debugToolKit.h"

versionInfo: GameID
        name = 'debugToolKit Library Demo Game'
        byline = 'Diegesis & Mimesis'
        desc = 'Demo game for the debugToolKit library. '
        version = '1.0'
        IFID = '12345'
	showAbout() {
		"This is a simple test game that demonstrates the features
		of the debugToolKit library.
		<.p>
		Consult the README.txt document distributed with the library
		source for a quick summary of how to use the library in your
		own games.
		<.p>
		The library source is also extensively commented in a way
		intended to make it as readable as possible. ";
	}
;
gameMain: GameMainDef
	initialPlayerChar = me
	inlineCommand(cmd) { "<b>&gt;<<toString(cmd).toUpper()>></b>"; }
	printCommand(cmd) { "<.p>\n\t<<inlineCommand(cmd)>><.p> "; }
;

startRoom: Room 'Void' "This is a featureless void.";
+me: Person;
+pebble: Thing '(small) (round) pebble' 'pebble' "A small, round pebble. ";

DefineDtkAction(Foozle, 'foozle', demoDebugger);

demoDebugger: DtkDebugger;
+DtkCommand 'foo' 'print the word <q>foo</q>'
	"This is a silly demonstration command that does nothing other
	than output the word <q>foo</q>.  Well, and hopefully it serves
	as a helpful example of how to declare a debugger command. "

	cmd() {
		output('A hollow voice says <q>foo</q>. ');
	}
;
+DtkCommand 'bar' +1 'print the word <q>bar</q>'
	"Like <b>foo</b>, but with <q>bar</q> and an argument. "

	cmd(arg) {
		output('A hollow voice says <q>bar</q> and also
			<q><<arg>></q>. ');
	}
;
// Note the +1 in the command declaration.  This means the command takes
// one argument (instead of the default zero arguments).
+DtkCommand 'look' +1 'show an object\'s desc'
	"Use <b>LOOK @[object name]</b> to display an object's description. "
	'LOOK @[object name]'
	cmd(obj) {
		if(!obj.ofKind(Thing)) {
			output('Argument is not a Thing.');
			return;
		}
		obj.desc();
	}
;
// Add the expression evaluator.
+DtkEval;

// Simple object for the expression evaluator to play with.
foo: object
	bar = nil
	log() { aioSay('\nfoo.bar = <<toString(bar)>>\n '); }
;
