#charset "us-ascii"
//
// debugToolKit.t
//
//	A TADS3/adv3 module for implementing simple, special-purpose
//	interactive debuggers in-game.
//
//	The basic idea is to provide a way to drop execution into
//	a simple debugging-only parser to examine/modify the game state.
//
//
// DECLARING A DEBUGGER
//
//	The module provides a DtkDebugger class for the debugger itself.
//	It provides a very simple, mostly self-contained command
//	parser.
//
//		// Declare the parser
//		demoDebugger: DtkDebugger;
//		// Add a "foo" command.
//		+DtkCommand 'foo' 'print the word <q>foo</q>'
//			"This command prints the word <q>foo</q>. "
//
//			command(arg) {
//				output('<q>Foo</q>. ');
//			}
//		;
//
//	This defines a debugger called demoDebugger and then adds a "foo"
//	command to its parser.  The parts of the command declaration are:
//
//		'foo'
//			A single-quoted string containing the command
//			string, in this case "foo".  This means the command
//			will be executed when "foo" is typed into the
//			debugger.
//
//		'print the word <q>foo</q>'
//			The short help message.  This will be listed by
//			the debugger's interal "help" command.
//
//		"This command prints the word <q>foo</q>. "
//			The long help message.  This will be displayed when
//			the command "help [command]" is typed into the
//			debugger, "help foo" in this case.
//
//		cmd(arg) {}
//			The method called when the command is executed.
//			The argument will contain anything after the command.
//			So in this case "foo 123" would call cmd() with the
//			argument "123".
//
//
#include <adv3.h>
#include <en_us.h>

#include "debugToolKit.h"

// Module ID for the library
debugToolKitModuleID: ModuleID {
        name = 'Debug Tool Kit Library'
        byline = 'Diegesis & Mimesis'
        version = '1.0'
        listingOrder = 99
}

class DtkOutputStream: OutputStream
	writeFromStream(txt) { aioSay(txt); }
;

// Mixin class for widgets that use or are used by the debugger.
class DtkObject: object
	// pointer to the debugger
	_dtk = nil

	getDebugger() { return(_dtk); }
	setDebugger(v) {
		if((v != nil) && !v.ofKind(DtkDebugger))
			return(nil);
		_dtk = v;

		return(true);
	}

	output(msg, svc?, ind?) { getDebugger().output(msg, svc, ind); }
;
