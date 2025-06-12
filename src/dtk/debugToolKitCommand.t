#charset "us-ascii"
//
// debugToolKitCommands.t
//
//
#include <adv3.h>
#include <en_us.h>

#include "debugToolKit.h"

#ifdef DTK

// Class for individual debugger commands
class DtkCommand: DtkObject
	// command keyword.  that's the actual typed command, like "exit"
	id = nil

	// short help message.  used in the list displayed by the "help" command
	help = '[this space intentionally left blank]'

	// long help message.  displayed for "help [command]"
	longHelp = "[this space intentionally left blank]"

	// Usage message for command
	usage = nil

	// Boolean flag.  If true, we're not listed by the help command.
	hidden = nil

	// Number of arguments
	argCount = 0

	// Stub command method.
	cmd() { return(nil); }
;

class DtkCmdExit: DtkCommand
	id = 'exit'
	help = 'exit the debugger'
	longHelp = "Use <q>exit</q> to exit the debugger and return to the
		game. "

	cmd(arg?) {
		output('Exiting debugger.');
		return(true);
	}
;

class DtkCmdBack: DtkCommand
	id = 'exit'
	help = 'exit this mode'
	longHelp = "Use <q>exit</q> to exit this mode and return to the
		main debugger. "
	cmd() { return(true); }
;

class DtkCmdHelp: DtkCommand
	id = 'help'
	help = 'display this message. use <q>help [command]</q> for more
		information'
	longHelp = "The <q>help</q> command displays a short help message,
		like this one. "

	cmd() {
		getDebugger().getCommandList().forEach(function(o) {
			if(o.hidden == true)
				return;
			output('<b><<o.id>></b>\t<<o.help>>');
		});
	}
;

class DtkCmdHelpArg: DtkCommand
	id = 'help'
	argCount = 1
	hidden = true

	cmd(arg) {
		local c;

		if((c = getDebugger().getCommand(arg)) == nil) {
			output('<q><b><<toString(arg)>></b></q>:
				Unknown debugger command');
			return;
		}

		c.longHelp();
	}
;

#endif // DTK
