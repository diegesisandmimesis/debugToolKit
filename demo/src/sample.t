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

DefineDtkDebuggerAction(Foozle, demoDebugger);
VerbRule(Foozle) 'foozle' : FoozleAction;

demoDebugger: DtkDebugger;
+DtkCommand 'foo' 'print the word <q>foo</q>'
	"This is a silly demonstration command that does nothing other
	than output the word <q>foo</q>.  Well, and hopefully it serves
	as a helpful example of how to declare a debugger command. "

	cmd(arg) {
		output('A hollow voice says <q>foo</q>. ');
	}
;
