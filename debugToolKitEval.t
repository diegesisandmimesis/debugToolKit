#charset "us-ascii"
//
// debugToolKitEval.t
//
//	A debugger "command" that evaluates arbitrary T3 expressions.
//
//
#include <adv3.h>
#include <en_us.h>

#include "debugToolKit.h"

class DtkEval: DtkCommand
	id = 'eval'
	help = 'switch to expression evaluator mode'
	longHelp = "The <q>eval</q> command enables expression evaluator
		mode.  In this mode you can type arbitrary TADS3 expressions
		and they will be compiled and executed. "

	_evalDebugger = nil

	cmd() {
		if(_evalDebugger == nil) {
			_evalDebugger = new DtkEvalDebugger();
			_evalDebugger.addDefaultCommands();
		}
		_evalDebugger.debugger(nil, nil, 'command line');
		return(true);
	}
;

class DtkCmdEvalExit: DtkCmdExit
	cmd() {
		return(nil);
	}
;

class DtkEvalDebugger: DtkDebugger
	defaultCommands = static [
		DtkCmdEvalExit, DtkCmdHelp, DtkCmdHelpArg, DtkEvalCmd
	]
	prompt = 'eval&gt;&gt;&gt; '

	debuggerBanner(lbl) {}

	handleNilCommand(txt) {
		local cmd;

		if((cmd = getCommand(DtkEvalCmd)) == nil) {
			inherited(txt);
			return;
		}

		cmd.cmd(txt);
	}
;

// A simple TADS3 expression evaluator.
// Accepts T3 source code as its arg, compiles it (if possible), executes
// it, and displays the return value.
class DtkEvalCmd: DtkCommand
	hidden = true
	cmd(txt) {
		local buf, fn, r;

		buf = new StringBuffer();
		buf.append('function() { return(');
		buf.append(txt);
		buf.append('); }');
		buf = toString(buf);

		try {
			fn = Compiler.compile(buf);
			r = fn();
		}

		catch(Exception e) {
			e.displayException();
			return;
		}

		output(toString(r));
	}
;
