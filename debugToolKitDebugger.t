#charset "us-ascii"
//
// debugToolKitDebugger.t
//
#include <adv3.h>
#include <en_us.h>
#include <dynfunc.h>

#include "debugToolKit.h"

#ifdef DTK

// Data structure for handling debugger operators and args
class DtkParseResult: object
	cmd = nil
	args = nil

	construct(v0, v1?) {
		cmd = v0;
		args = v1;
	}
;

// The debugger itself
class DtkDebugger: PreinitObject
	sortCommands = nil		// alphabetically sort command list?
					// default is nil, cmds listed in order
					// declared

	prompt = '&gt;&gt;&gt; '	// debugger prompt
	prefix = ''			// output prefix
	spacer = '====='		// output spacer.  nil for none
	padding = '==='			// padding for debug banners
	indentChr = '\t'		// indentation character

	transcript = nil		// saved "real" transcript
	stream = nil			// saved "real" output stream

	// Default commands to add to every debugger.  We always
	// add the standard help and exit commands.
	defaultCommands = static [ DtkCmdExit, DtkCmdHelp, DtkCmdHelpArg ]

	// Lookup table for the debugger command objects
	commands = perInstance(new Vector())

	// Method we'll hang a compiled express on if we need to resolve
	// keywords into objects
	_compiledDebuggerArg = nil

	// Rexen for command parsing
	_skipRexen = static [ '^$', '^<space>*$' ]
	_helpRex = '^<space>*<question><space>*$'
	_cmdSplitRex = '<space>+'
	_cmdSplitRexPattern = nil

	// Debugger lock.  Probably not needed
	_debuggerLock = nil

	// Preinit method.  Sets up command objects
	execute() {
		forEachInstance(DtkCommand, function(o) {
			self.addCommand(o);
		});
		addDefaultCommands();
	}

	addDefaultCommands() {
		local obj;

		if(defaultCommands == nil)
			return;

		if(!defaultCommands.ofKind(Collection))
			defaultCommands = [ defaultCommands ];

		defaultCommands.forEach(function(o) {
			if(getCommand(o))
				return;

			obj = o.createInstance();
			obj.location = self;
			addCommand(obj);
		});
	}

	// Convenience method for valToSymbol
	v2s(v) { return(reflectionServices.valToSymbol(v)); }

	// Output formatter.  Mostly for handling indentation
	formatOutput(msg, svc?, ind?) {
		local r;

		if(msg == nil)
			return('');

		r = new StringBuffer();
		if(svc == nil)
			svc = prefix;

		if(svc.length > 0) {
			r.append(svc);
			r.append(': ');
		}

		if(ind)
			r.append(indent(ind));

		r.append(msg);

		return(toString(r));
	}

	indent(n) {
		local i, r;

		if(n == nil) n = 1;
		r = new StringBuffer(n * 2);
		for(i = 0; i < n; i++)
			r.append(indentChr);
		return(toString(r));
	}

	// Generic output method
	output(msg, svc?, ind?)
		{ aioSay('\n<<formatOutput(msg, svc, ind)>>\n '); }

	addCommand(obj) {
		if((obj == nil) || !obj.ofKind(DtkCommand))
			return(nil);

		commands.appendUnique(obj);
		obj.setDebugger(self);

		return(true);
	}

	getCommand(cls) {
		local k;

		if(cls == nil)
			return(nil);

		if(cls.ofKind(String))
			k = commands.subset({ x: x.id == cls });
		else
			k = commands.subset({ x: x.ofKind(cls) });

		if(k.length > 0)
			return(k[1]);

		return(nil);
	}

	getCommandList() {
		if(!sortCommands)
			return(commands);
		return(commands.sort(nil,
			{ a, b: toString(a.id).compareTo(toString(b.id)) }));
	}

	// Handle the debugger lock
	_setDebuggerLock(v) {
		if(_debuggerLock == v)
			return(nil);
		_debuggerLock = v;
		return(true);
	}

	banner(txt) {
		output('<<padding>><<txt>><<padding>>');
	}

	// Main debugger loop
	debugger(data, t?, lbl?) {
		if(!startDebugger(t))
			return;
		debuggerBanner(lbl);
		debuggerLoop(t);
		stopDebugger();
	}

	startDebugger(t) {
		if(t == nil)
			t = gTranscript;

		if(!_setDebuggerLock(true))
			return(nil);

		setDebugOutput(t);

		return(true);
	}

	stopDebugger() {
		// Switch the output stream and transcript
		// back to where they were before we started
		unsetDebugOutput();

		// Clear our lock
		_setDebuggerLock(nil);
	}


	debuggerBanner(lbl) {
		if(lbl == nil)
			lbl = 'unknown';

		// Startup banner
		banner('breakpoint in <<lbl>>');
		banner('type HELP or ? for information on the interactive
			debugger');
	}

	debuggerLoop(t) {
		local cmd;

		// Input/command loop
		for(;;) {
			// Display our command prompt
			// IMPORTANT:  we can't use output() here because
			//	that would put a newline after the prompt
			aioSay('\n<<prompt>>');

			// Keep accepting and processing commands until
			// the command handler returns nil
			cmd = inputManager.getInputLine(nil, nil);
			if(handleDebuggerInput(cmd) == true) {
				// Return to the game
				return;
			}
		}
	}

	// Turn off the game's main transcript and output stream, substituting
	// our own.
	setDebugOutput(t) {
		// Remember the current settings, so we can restore them later
		stream = outputManager.curOutputStream;
		transcript = t;
		
		// Set our new stream and transcript
		outputManager.setOutputStream(new DtkOutputStream);
		gTranscript = new CommandTranscript();
	}

	// Undo the stuff we did in setDebugOutput() above
	unsetDebugOutput() {
		outputManager.setOutputStream(stream);
		outputManager.curTranscript = transcript;
		gTranscript = transcript;

		transcript = nil;
	}

	// Command execution cycle, such as it is
	handleDebuggerInput(txt) {
		local cmd, data;

		// Parse the input string, returning a parse result object.
		// A return of nil means an empty(-ish) command line, so
		// we just immediately return (to go through the input
		// loop again)
		if((data = parseDebuggerInput(txt)) == nil)
			return(nil);

		if(data.cmd == nil) {
			output('Unknown command.');
			return(nil);
		}

		// Try to resolve the command string into a command object
		if((cmd = parseDebuggerCommand(data, txt)) == nil)
			return(nil);

		if(parseDebuggerArgs(data) == nil)
			return(nil);

		return(execDebuggerCommand(cmd, data));
	}

	// Attempt to parse the input string as a debugger command.
	// We return either nil (do nothing) or a DtkParseResult instance
	// (holding the command and any arguments)
	parseDebuggerInput(txt) {
		local ar, i;

		// No command, nothing to do
		if(txt == nil)
			return(nil);

		// Check our various "no command in input" regexen
		for(i = 1; i <= _skipRexen.length; i++)
			if(rexMatch(_skipRexen[i], txt) != nil)
				return(nil);

		// Special case:  see if the input is "?", and handle it
		// as if the input was "help"
		if(rexMatch(_helpRex, txt) != nil)
			return(new DtkParseResult('help'));

		// Now we compile the regex we'll use to split the
		// input string into word-ish bits.
		if(_cmdSplitRexPattern == nil)
			_cmdSplitRexPattern = new RexPattern(_cmdSplitRex);

		// Split the command.
		ar = txt.split(_cmdSplitRexPattern);

		// If we didn't get ANY word-like things, bail.
		if(ar.length < 1)
			return(new DtkParseResult(nil));

		// Convert all the bits into lower case (we don't do
		// this to the input string itself because we might
		// later try to evaluate it as a raw TADS3 expression).
		ar = ar.mapAll({ x: x.toLower() });

		// Handle the special case where we got exactly one
		// word, which is a command without arguments.
		if(ar.length == 1)
			return(new DtkParseResult(ar[1]));

		// Return the parse result.  First arg is the command,
		// second is the arg list.
		return(new DtkParseResult(ar[1], ar.splice(1, 1)));
	}

	// Do any special handling required by the argument.
	// Returning true means "continue evaluation" and nil means
	// "something bad happened, fail".
	parseDebuggerArgs(op) {
		local i;

		// No args, nothing to do
		if(op.args == nil)
			return(true);

		_parseDebuggerArgs(op);

		for(i = 1; i <= op.args.length; i++) {
			if(op.args[i] == nil) {
				output('Unknown object, argument
					<<toString(i)>>.');
				return(nil);
			}
		}

		return(true);
	}

	_parseDebuggerArgs(op) {
		local i, r, v;

		// New vector for the modified arg list we're about to
		// create.
		v = new Vector(op.args.length);

		for(i = 1; i <= op.args.length; i++) {
			// Resolve the arg
			r = _resolveDebuggerArg(op.args[i]);

			// Add it to the results vector.
			v.append(r);
		}

		// Replace the arg list.
		op.args = v;
	}

	// Figure out what to do with a single debugger command argument
	_resolveDebuggerArg(arg) {
		// If the arg doesn't start with an @, treat it as a literal.
		if(!arg.startsWith('@'))
			return(arg);

		// The arg starts with an @, so we try to evaluate
		// everything after the @ as a (TADS3) object name
		return(_compileDebuggerArg(arg.substr(2)));
	}

	// Here we build and compile an expression to get a reference to a
	// named object.
	_compileDebuggerArg(arg) {
		local buf, r;

		// Construct the source for a function that returns the
		// value of an object named in the arg.
		buf = new StringBuffer();
		buf.append('function() { return(');
		buf.append(arg);
		buf.append('); }');
		buf = toString(buf);

		// Try compiling the expression we constructed above, setting
		// the compiled expression as our _compiledDebuggerArg()
		// method.  The we get the value returned by the method.
		try {
			setMethod(&_compiledDebuggerArg, Compiler.compile(buf));
			r = _compiledDebuggerArg();
		}
		// If something went wrong (for example the arg gave the
		// name of an object that doesn't exist) the compiler will
		// throw an exception, which we catch here, displaying the
		// exception message.
		catch(Exception e) {
			e.displayException();
			r = nil;
		}
		// Return whatever we ended up with.
		finally {
			return(r);
		}
	}

	// Given a resolve results object, try to get the corresponding
	// command object for its command.
	parseDebuggerCommand(op, txt) {
		local c, err, i, k;

		c = (op.args ? op.args.length : 0);

		// Okay, first we go through all of the commands (as
		// string literals).
		k = commands.subset({ x: x.id == op.cmd });
		for(i = 1; i <= k.length; i++) {
			// If the arg count matches, immediately
			// return.
			if(k[i].argCount == c) {
				return(k[i]);
			} else {
				// The arg count DOESN'T match, so
				// we make a note of the failure.
				// We don't immediately error out
				// so we can handle commands with
				// variable argument counts (like
				// the builtin "help" command).
				err = k[i];
			}
		}

		// If we got an error above and reached here afterward, that
		// means we didn't find any version of the command that matched
		// our input arg count.  So now we error out.
		if(err != nil) {
			output('Bad arg count for command <<op.cmd>>.');
			return(nil);
		}

		// Generic error.
		//output('Unknown command. ');
		handleNilCommand(txt);
		return(nil);
	}

	handleNilCommand(txt) {
		output('Unknown command.');
	}

	// Try to execute the command
	// Arg is a DtkParseResult instance
	execDebuggerCommand(cmd, op) {
		if(op.args == nil)
			return(cmd.cmd());
		return(cmd.cmd(op.args...));
	}
;

#endif // DTK
