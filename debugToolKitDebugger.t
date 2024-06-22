#charset "us-ascii"
//
// debugToolKitDebugger.t
//
#include <adv3.h>
#include <en_us.h>
#include <dynfunc.h>

#include "debugToolKit.h"

// Data structure for handling debugger operators and args
class DtkParseResult: object
	cmd = nil
	arg = nil
	obj = nil

	construct(v0, v1?, v2?) {
		cmd = v0;
		arg = v1;
		obj = v2;
	}
;

// The debugger itself
class DtkDebugger: PreinitObject
	prompt = '&gt;&gt;&gt; '	// debugger prompt
	prefix = ''			// output prefix
	spacer = '====='		// output spacer.  nil for none
	padding = '==='			// padding for debug banners
	indentChr = '\t'		// indentation character

	transcript = nil		// saved "real" transcript
	stream = nil			// saved "real" output stream

	// Default commands to add to every debugger.  We always
	// add the standard help and exit commands.
	defaultCommands = static [ DtkCmdExit, DtkCmdHelp ]

	// Lookup table for the debugger command objects
	commands = perInstance(new LookupTable())

	// Rexen for command parsing
	_skipRexen = static [ '^$', '^<space>*$' ]
	_helpRex = '^<space>*<question><space>*$'
	_niladicRex = '^<space>*(<alpha>+)<space>*$'
	_unaryRex = '^<space>*(<alpha>+)<space>+(<AlphaNum>+)<space>*$'
	_objRex = '^<space>*(<alpha>+)<space>+@(<AlphaNum>+)<space>*$'

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

		commands[obj.id] = obj;
		obj.setDebugger(self);

		return(true);
	}

	getCommand(cls) {
		local i, k;

		if(cls == nil)
			return(nil);

		if(cls.ofKind(String))
			return(commands[cls]);

		k = commands.keysToList();
		for(i = 1; i <= k.length; i++) {
			if(commands[k[i]].ofKind(cls))
				return(commands[k[i]]);
		}

		return(nil);
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
			if(handleDebuggerCommand(cmd) != true) {
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
	handleDebuggerCommand(txt) {
		local r;

		if((r = parseDebuggerCommand(txt)) == nil)
			return(true);

		if(r.arg != nil) {
			if(!parseDebuggerArg(r))
				return(true);
		}

		return(execDebuggerCommand(r));
	}

	// Attempt to parse the input string as a debugger command, possibly
	// with an argument
	// We return either nil (do nothing) or a DtkParseResult instance
	// (holding the command and maybe arg)
	parseDebuggerCommand(txt) {
		local c, i;

		// No command, nothing to do
		if(txt == nil)
			return(nil);

		// Check our various "no command in input" regexen
		for(i = 1; i <= _skipRexen.length; i++)
			if(rexMatch(_skipRexen[i], txt) != nil)
				return(nil);

		// Special case:  see if the input is "?", and handle it
		// as if the input was "help" if so
		if(rexMatch(_helpRex, txt) != nil) {
			if((c = getCommand(DtkCmdHelp)) == nil)
				return(handleUnknownCommand(txt));
			c.cmd();
			return(nil);
		}

		// See if we have a command with no arg
		if(rexMatch(_niladicRex, txt) != nil)
			return(new DtkParseResult(
				rexGroup(1)[3].toLower()));

		// See if we have a command and an arg
		if(rexMatch(_unaryRex, txt) != nil)
			return(new DtkParseResult(
				rexGroup(1)[3].toLower(),
				rexGroup(2)[3].toLower()));

		if(rexMatch(_objRex, txt) != nil)
			return(new DtkParseResult(
				rexGroup(1)[3].toLower(),
				rexGroup(2)[3].toLower(), true));

		// Punt.
		return(handleUnknownCommand(txt));
	}

	// Do any special handling required by the argument.
	parseDebuggerArg(op) {
		local buf;

		// Arg is just a literal, nothing to do.
		if(op.obj != true)
			return(true);

		buf = new StringBuffer();
		buf.append('function() { return(');
		buf.append(op.arg);
		buf.append('); }');
		buf = toString(buf);

		try {
			setMethod(&_parseDebuggerArg, Compiler.compile(buf));
			op.arg = _parseDebuggerArg();
		}
		catch(Exception e) {
			e.displayException();
			return(nil);
		}

		return(true);
	}

	_parseDebuggerArg = nil

	handleUnknownCommand(txt) {
		// Dunno what we got, complain
		"\nUnknown debugger command.\n ";
		return(nil);
	}

	// Try to execute the command
	// Arg is a DtkParseResult instance
	execDebuggerCommand(op) {
		local i, k;

		k = commands.keysToList();
		for(i = 1; i <= k.length; i++) {
			if(k[i] == op.cmd)
				return(commands[k[i]].cmd(op.arg));
		}

		// Didn't match anything, complain
		"\nUnknown debugger command.\n ";

		return(true);
	}

	isNumber(v)
		{ return(rexMatch('^<space>*(<Digit>+)<space>*$', v) != nil); }
;
