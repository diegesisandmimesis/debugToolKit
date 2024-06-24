#charset "us-ascii"
//
// debugToolKitCommands.t
//
//
#include <adv3.h>
#include <en_us.h>

#include "debugToolKit.h"

// Class for individual debugger commands
class DtkCommand: DtkObject
	// command keyword.  that's the actual typed command, like "exit"
	id = nil

	// short help message.  used in the list displayed by the "help" command
	help = '[this space intentionally left blank]'

	// long help message.  displayed for "help [command]"
	longHelp = "[this space intentionally left blank]"

	// Boolean flag.  If true, we're not listed by the help command.
	hidden = nil

	// Number of arguments
	argsCount = 0

	cmd(arg?) { return(true); }			// command method
;

class DtkCmdExit: DtkCommand
	id = 'exit'
	help = 'exit the debugger'
	longHelp = "Use <q>exit</q> to exit the debugger and returh to the
		game. "

	cmd(arg?) {
		output('Exiting debugger.');
		return(nil);
	}
;

class DtkCmdHelp: DtkCommand
	id = 'help'
	help = 'display this message. use <q>help [command]</q> for more
		information'
	longHelp = "The <q>help</q> command displays a short help message,
		like this one. "

	cmd(arg?) {
		if(arg == nil)
			return(genericHelp());

		return(commandHelp(arg));
	}
	genericHelp() {
		getDebugger().commands.forEachAssoc(function(k, v) {
			output('<b><<k>></b>\t<<v.help>>');
		});

		return(true);
	}
	commandHelp(arg) {
		local c;

		if((c = getDebugger().commands[arg]) == nil) {
			output('<q><b><arg</b></q>: Unknown debugger command');
			return(true);
		}

		c.longHelp();

		return(true);
	}
;
