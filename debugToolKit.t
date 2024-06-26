#charset "us-ascii"
//
// debugToolKit.t
//
//	A TADS3/adv3 module for implementing simple, special-purpose
//	interactive debuggers in-game.
//
//	A debugger in this context means a lightweight modal interface
//	that's only available in debugging builds.
//
//
// SIMPLE USAGE
//
//	To create a debugger just declare an instance of the DtkDebugger
//	class:
//
//		// Declare a debugger.
//		demoDebugger: DtkDebugger;
//
//	Now any code that calls demoDebugger.debugger() will cause
//	execution to drop into the debugger.  Usage for the debugger()
//	method is:
//
//		debugger(data, t?, lbl?)
//
//			data	An arbitrary data object.  Presumably
//				whatever you want to debug, but it's
//				left to the instance to decide what
//				if anything to do with it).
//				No default.
//
//			t	Optional reference to the transcript.  This
//				transcript will be disabled while the
//				debugger is running, and restored when
//				the debugger exits.
//				Defaults to gTranscript.
//
//			lbl	Optional label for the debugger banner.  This
//				will be displayed when the debugger starts.
//				It is intended to clarify what called
//				the debugger.
//
//	When the debugger() method is called normal TADS3 command execution
//	is suspended and a simple, self-contained parser is used to
//	handle debugging commands.
//
//	By default the debugger includes the following commands:
//
//		exit		Exits the debugger, returning to normal
//				game mode.
//
//		help		Displays help for the debugger.  The help
//				command will automatically enumerate the
//				available debugger commands along with a
//				short description of each.
//				You can also use "help [command]" for
//				a more detailed help message for the given
//				debugger command.
//
//
// DEFINING NEW COMMANDS
//
//	The default debugger doesn't actually do much of anything, so
//	in order to do actual debugging you'll have to declare your own
//	debugging commands.
//
//	The module provides a base DtkCommand class for commands.  Its
//	properties include:
//
//		id		A single-quoted string used as the command
//				keyword.
//				Example: 'exit'
//
//		help		A single-quoted string used as the short
//				help message.  This is displayed alongside
//				the command keyword in the "help" listing.
//				Example: 'exit the debugger'
//
//		longHelp	A double-quoted string used as the long
//				help message.  This is displayed in response
//				to "help [command]" for this command.
//				Example: "The <q>exit</q> command exits
//				the debugger. "
//
//		argCount	The number of arguments this command accepts.
//				Default is 0
//
//		hidden		A boolean flag.  If true, the "help" command
//				will not list this command.
//				Default is nil
//
//		cmd(args...)	The method called to execute the command.
//				It will be called with whatever args (if any)
//				are given in the debugger command line.
//				IMPORTANT:  This method needs to return
//					boolean nil (or not return a value at
//					all) if the debugger should continue
//					operation after executing the command.
//					A return value of true will cause
//					the debugger to exit.
//
//		output(txt, n?)	Convenience method to output messages via
//				the debugger.
//				The first argument is the text to output.
//				The optional second argument is the indentation
//				level to use (default is zero, or no
//				indentation).
//
//
//	The module provides a template for declaring debugger commands
//	(question marks indicate an optional property):
//
//		DtkCommand 'id' +argCount? 'help'? "longHelp"?;
//
//	Commands are added to debuggers via the standard TADS3 lexical
//	ownership syntax.  That's the +[declaration] syntax:
//
//		// Declare a debugger.
//		demoDebugger: DtkDebugger;
//		// Add a simple command.
//		+DtkCommand 'foo' 'print the word <q>foo</q>'
//			"This command prints the word <q>foo</q>. "
//			cmd() {
//				output('<q>Foo</q>.');
//			}
//		;
//
//
// DECLARING DEBUGGER ACTIONS
//
//	In addition to programmatically calling the debugger() method
//	from existing code you can declare a debugging action using the
//	DefineDtkAction macro.  Example:
//
//		DefineDtkAction(Foozle, 'foozle', demoDebugger);
//
//	This declares a new action, FoozleAction.  It is invoked via
//	>FOOZLE on the normal TADS3 command line.  When invoked, >FOOZLE
//	will start the debugger demoDebugger.
//
//
// EXPRESSION EVALUATOR
//
//	In addition to normal commands the module supplies a simple TADS3
//	expression evaluator that can be added to debuggers.
//
//	The class is DtkEval, and it can be added the same way other
//	commands are added:
//
//		// Declare a debugger.
//		demoDebugger: DtkDebugger;
//		// Add the expression evaluator.
//		+DtkEval;
//
//	In the debugger, use the "eval" command to enter expression
//	evaluator mode.
//
//	In the expression evaluator the prompt will change to "eval>>>"
//	and input will be parsed as TADS3 source code.
//
//	For example, if the game defines an object foo with a property
//	bar that is initially nil:
//
//		>>>eval				// enter evaluator mode
//		eval>>> foo.bar			// display current value
//		nil				// foo.bar is nil
//		eval>>> foo.bar = 123		// set foo.bar to be 123
//		123				// return value from assignment
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
