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
#include "dataTypes.h"

#define pgClass gameMain.doorClass

demoDebugger: RefcountDebugger;

class DemoDoor: Door
	//finalize() { aioSay('\nfinalize()\n '); }
;

versionInfo: GameID;
gameMain: GameMainDef
	doorClass = DemoDoor
	initialPlayerChar = me
	newGame() {
		FoozleAction.swapDoors();
		inherited();
	}

	makeDoors() {
		local i;

		for(i = 0; i < 100; i++)
			FoozleAction.swapDoors();

		t3RunGC();
		i = 0;
		forEachInstance(DemoDoor, { x: i += 1 });
		"\ninstances = <<toString(i)>>\n ";
	}
;

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
		d.moved = nil;
	}
;

DefineSystemAction(Foozle)
	execSystemAction() {
		swapDoors();
	}

	swapDoors() {
		clearDoors();
		createDoors();
	}

	clearDoors() {
		forEachInstance(Room, { x: x.clearDoor() });
		libGlobal.connectionCache = nil;
		libGlobal.canTouchCache = nil;
		libGlobal.actorVisualAmbientCache = nil;
		libGlobal.senseCache = nil;
		libGlobal.invalSenseCache();
	}

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

DefineSystemAction(Dtk)
	execSystemAction() {
		demoDebugger.debugger(nil, nil, 'command line');
	}
;
VerbRule(Dtk) 'dtk' : DtkAction
	verbPhrase = 'dtk/dtking';


DefineSystemAction(Foo)
	execSystemAction() {
		local r;

		r = __refcountDebuggerEnumerator.searchEach(DemoDoor);
		RefcountDebugger.logResults(r);
	}
;
VerbRule(Foo) 'foo' : FooAction verbPhrase = 'foo/fooing';
