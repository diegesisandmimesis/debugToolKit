#charset "us-ascii"
//
// baseTest.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// This is a very simple demonstration "game" for the debugToolKit library.
//
// It can be compiled via the included makefile with
//
//	# t3make -f baseTest.t3m
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

versionInfo: GameID;
gameMain: GameMainDef initialPlayerChar = me;

startRoom: Room 'Void' "This is a featureless void.";
+me: Person;
+pebble: Thing '(small) (round) pebble' 'pebble' "A small, round pebble. ";

foo: object bar = nil;

DefineDtkDebuggerAction(Foozle, demoDebugger);
VerbRule(Foozle) 'foozle' : FoozleAction;

demoDebugger: DtkDebugger;
+DtkEval;
