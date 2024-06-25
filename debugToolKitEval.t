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

// A simple TADS3 expression evaluator.
// Accepts T3 source code as its arg, compiles it (if possible), executes
// it, and displays the return value.
class DtkEval: DtkCommand
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
