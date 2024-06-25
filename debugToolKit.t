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
// DEBUGGERS
//
//	The module provides a DtkDebugger class for the debugger itself.
//	It provides a very simple, mostly self-contained command
//	parser.
//
//		// Declare the debugger.
//		demoDebugger: DtkDebugger;
//
//	In general you'll only have to modify the debugger itself if you
//	want to fiddle with parsing or to add utility methods that
//	can be accessed by commands.
//
//	By default a debugger instance comes with the following built-in
//	debugger commands:
//
//		exit
//			Exits the debugger.
//
//		help
//			Enumerates defined debugger commands and their
//			short help messages
//
//		help [cmd]
//			Displays the long help message for the given command
//
//
// DEBUGGER COMMANDS
//
//	The module provides a DtkCommand object for debugger commands.
//	Commands should be added to debugger instances via the standard
//	TADS3 lexical ownership syntax (example below).  Commands are
//	automatically available the debugger they're declared on.
//
//	Important command properties:
//
//		id
//			A single-quoted string used as the command keyword
//			Example: 'exit'
//
//		help
//			A single-quoted string used as the "short" help
//			message.  This is displayed alongside the command
//			keyword by the debugger's builtin "help" command.
//			Example: 'exit the debugger'
//
//		longHelp
//			A double-quoted string used as the "long" help
//			message.  This is displayed by the debugger for
//			"help [command]".
//			Example: "The <q>exit</q> command exits the debugger."
//
//		argCount
//			The number of arguments this command takes.
//			Default is 0
//
//		hidden
//			A boolean flag.  If true, the "help" command won't
//			list this command.
//			Default is nil
//
//		cmd()
//			The method called when the command is executed.
//			It will be called with whatever args (if any) were
//			specified on the debugger input.
//
//
//	The module provides a template for declaring debugger commands
//	(question marks indicate an optional argument to the template).
//
//		DtkCommand 'id' +argCount? 'help'? "longHelp"?;
//
//
// DEBUGGER COMMAND EXAMPLES
//
//	Here's a basic command declaration, including the debugger
//	declaration (which will be omitted in subsequent examples).
//
//		demoDebugger: DtkDebugger;
//		+DtkCommand 'foo' 'print the word <q>foo</q>'
//			"This command prints the word <q>foo</q>. "
//
//			cmd() {
//				output('<q>Foo</q>. ');
//			}
//		;
//
//	By default a command takes no arguments.  To declare a command
//	that does take arguments:
//
//		+DtkCommand 'bar' +1 'the word <q>bar</q> and an argument'
//			"This command prints the word <q>bar</q>
//			and a single argument. "
//
//			cmd(arg) {
//				output('<q>Bar</q> and also <q><<arg>></q>. ');
//			}
//
//	The +1 in the declaration above is the number of arguments.
//
//
// USING THE DEBUGGER
//
//	Calling DtkDebugger.debugger() drops execution into the debugger.
//	Usage is:
//
//		debugger(data, t?, lbl?)
//			data
//				An arbitrary data object (presumably
//				whatever you want to debug, but it's
//				left to the instance to decide what
//				if anything to do with it)
//			t
//				Optional reference to the transcript.
//				Defaults to gTranscript.
//			lbl
//				Optional label for the debugger banner.
//				This will be displayed when the debugger
//				starts and is intended to clarify what
//				called the debugger.
//
//
//	In addition to calling the debugger() method programmatically (in
//	an exception handler or something like that) you can declare
//	a debugging action using the DefineDtkDebuggerAction macro. Example:
//
//		DefineDtkDebuggerAction(Foozle, demoDebugger);
//		VerbRule(Foozle) 'foozle' : FoozleAction;
//
//	This declares FoozleAction, invoked with >FOOZLE on the regular
//	in-game command prompt, which will call demoDebugger.debugger().
//
//	By default an action declared this way will be called with a nil
//	data argument.  If you want to do something else, you can
//	supply a different startDebugger() method.  The default one is:
//
//		startDebugger(obj) { obj.debugger(nil, nil, 'command line'); }
//
//	The argument to startDebugger() is the debugger object.
//
//
// THE DEBUGGER COMMAND LINE
//
//	Using the above example (also found in the demo in
//	./demo/src/sample.t), we can drop into the debugger from normal
//	game execution via the >FOOZLE action we declared:
//
//		Void
//		This is a featureless void.
//
//		You see a pebble here.
//
//		>foozle
//		===breakpoint in command line===
//		===type HELP or ? for information on the interactive debugger===
//		>>>
//
//	Now we're in the debugger's simple parser, which only understands
//	the debugging commands we've defined.  In the demo:
//
//		>>> help
//		foo    print the word "foo"
//		bar    print the word "bar"
//		look   show an object's desc
//		exit   exit the debugger
//		help   display this message. use "help [command]" for more
//			information
//		>>>
//
//
// EXPRESSION EVALUATOR
//
//	In addition to "normal" commands, the module supplies a TADS3
//	expression evaluator that can be added to debuggers.
//
//	The class is DtkEval, and it can be added the same way you
//	add commands:
//
//		// Declare the debugger.
//		demoDebugger: DtkDebugger;
//		// Add the expression evaluator.
//		+DtkEval;
//
//	In the debugger, use the "eval" command to enter expression
//	evaluator mode pass.  The prompt will change to "eval>>>" and
//	you can then pass expressions to evaluator by just typing them
//	on the command line.  For example, given an object "foo" with a
//	property "bar" that is initially nil:
//
//		>>>eval				// enter evaluator mode
//		eval>>> foo.bar			// display foo.bar
//		nil				// foo.bar is now nil
//		eval>>> foo.bar = 123		// set foo.bar = 123
//		123				// return value of expression
//		eval>>> foo.bar			// display foo.bar again
//		123				// value is now 123
//		eval>>> exit			// exit evaluator mode
//		>>>				// back at debug prompt
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
