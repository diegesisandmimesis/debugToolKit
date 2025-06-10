#charset "us-ascii"
//
// refcountTest.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// This is a very simple demonstration "game" for the procgen library.
//
// It can be compiled via the included makefile with
//
//	# t3make -f refcountTest.t3m
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

// Declare a generic debug toolkit debugger instance and add the refcount
// debugger to it.
// This gives you the normal debugger (otherwise empty in this case) and
// configures it to have a debugger command (refcount, displayed in the
// help menu) that switches to the refcount debugger.
demoDebugger: DtkDebugger;
+DtkRefcount;

// Declare a standalone refcount debugger.  This can be invoked directly,
// as opposed to the one above which gets set up as part of the "main"
// debugger.
refcountDebugger: RefcountDebugger;

// Convenience definition for the class we'll be referencing a lot in this
// demo.
#define pgClass gameMain.doorClass

// The class definition.  It's just a door class, and it's only getting
// a subclass to make it easier to separate in versions of this demo
// that involve other door classes.
class DemoDoor: Door
	//finalize() { aioSay('\nfinalize()\n '); }
;

versionInfo: GameID;
gameMain: GameMainDef
	// Just putting the class somewhere the pgClass macro can get it.
	doorClass = DemoDoor

	initialPlayerChar = me

	inlineCommand(cmd) { "<b>&gt;<<toString(cmd).toUpper()>></b>"; }
	printCommand(cmd) { "<.p>\n\t<<inlineCommand(cmd)>><.p> "; }

	newGame() {
		// Before we even start we swap the doors, using the
		// logic implemented in the Foozle action class (defined
		// below).
		// This can be used to test the fact that dangling references
		// to door instances aren't created until the first turn;
		// you can invoke the command below as many times as you
		// want and you'll never end up with more than two door
		// instances (if you run garbage collection before checking).
		FoozleAction.swapDoors();

		inherited();
	}

	showIntro() {
		"This demo was put together as a testbed for dynamic door
		creation and (hopefully) deletion.
		<.p>The <<inlineCommand('dtk')>> command drops into the
		interactive debugger, <<inlineCommand('refcount')>> drops
		directly into the object reference debugger,
		and <<inlineCommand('foo')>> can be used to display a
		summary of the references for the DemoDoor class.
		<.p>The <<inlineCommand('foozle')>> command shuffles the
		door, replacing the current doors connecting startRoom and
		northRoom with new instances.  This <b>should</b> free
		the old door pair to be garbage collected, but this does
		not appear to be true.  Hence this demo.<.p> ";
	}
;

// Tiny little gameworld.
// The start and north rooms are the ones that get connected by dynamically
// created doors.  The south room is there to give someplace to travel
// without interacting with the doors, and the void is there so other
// versions of this demo can put the player outside of contiguous sense
// containment with the doors.
void: Room 'Void' "This is the void. ";

startRoom: Room 'Starting Room' "This is the starting room. "
	north = northRoom
	south = southRoom
;
+me: Person;

northRoom: Room 'North Room' "This is the north room. "
	south = startRoom
;

southRoom: Room 'South Room' "This is the south room. "
	north = startRoom
;

// Update the base room class to add logic to remove a door.  This
// is what we'd hope would free the door(s) for garbage collection.
modify Room
	clearDoor() {
		contents.forEach({ x: _clearDoor(x) });
	}
	_clearDoor(d) {
		if((d == nil) || !d.ofKind(pgClass)) return;
		Direction.allDirections().forEach(function(dir) {
			if(self.(dir.dirProp) == d)
				self.(dir.dirProp) = nil;
		});
		d.otherSide = nil;
		d.masterObject = nil;
		d.moveInto(nil);
	}
;

// Action that gets rid of the existing doors connecting startRoom and
// northRoom and creates a new pair.
DefineSystemAction(Foozle)
	execSystemAction() {
		swapDoors();
		"\nDoors shuffled.\n ";
	}

	swapDoors() {
		clearDoors();
		createDoors();
	}

	// Clear the existing doors.
	clearDoors() {
		forEachInstance(Room, { x: x.clearDoor() });

		// Clear all libGlobal caches.
		//libGlobal.connectionCache = nil;
		//libGlobal.canTouchCache = nil;
		//libGlobal.actorVisualAmbientCache = nil;
		//libGlobal.senseCache = nil;
		//libGlobal.invalSenseCache();
	}

	// Create and connect new doors.
	createDoors() {
		local d0, d1;

		d0 = pgClass.createInstance();
		d1 = pgClass.createInstance();
		d1.masterObject = d0;
		d0.otherSide = d1;
		d1.otherSide = d0;
		d0.moveInto(startRoom);
		d1.moveInto(northRoom);
		startRoom.north = d0;
		northRoom.south = d1;
	}
;
VerbRule(Foozle) 'foozle' : FoozleAction
	verbPhrase = 'foozle/foozling';

DefineDtkAction(Refcount, 'refcount', refcountDebugger);
DefineDtkAction(Dtk, 'dtk', demoDebugger);

// Command that does what the refcount debugger does, only
// directly in a command instead of in a debugger interface.
DefineSystemAction(Foo)
	execSystemAction() {
		local r;

		dtkRunGC();
		r = __refcountDebuggerEnumerator.searchEach(DemoDoor);
		RefcountDebugger.logResults(r);
	}
;
VerbRule(Foo) 'foo' : FooAction verbPhrase = 'foo/fooing';
