#charset "us-ascii"
//
// refcountDebugger.t
//
//	Debugger for backtracking object references.
//
//	Useful if you have dynamically-created objects that aren't
//	getting garbage collected and you want to identify why.
//
//
#include <adv3.h>
#include <en_us.h>
#include <dynfunc.h>

#include "debugToolKit.h"

#ifdef DTK

modify TadsObject
	__equals(obj) {
		if(dataType(self) != dataType(obj))
			return(nil);
		return(self == obj);
	}
;

class _DtkSearchResult: object
	obj = nil
	match = nil
	construct(v0, v1) { obj = v0; match = v1; }
;

class _DtkObjMatch: object
	obj = nil
	prop = nil
	construct(v0, v1) { obj = v0; prop = v1; }
;

class RDCmd: DtkCommand
	output(msg, svc?, ind?) { _dtk.output(msg, svc, ind); }
;

class RefcountDebugger: DtkDebugger
	name = 'refcount'

	defaultCommands = static [
		DtkCmdExit, RDRefcount, DtkCmdHelp, DtkCmdHelpArg
	]

	_logLine(idx, v0, v1) {
		"\n<<sprintf('%_ -5s%_ -30s%_ -30s', idx, v0, v1)>>";
	}

	logResults(r) {
		local i, j, l;

		if(r.length == 0) {
			"no matches";
			return;
		}
		"<pre>";
		_logLine('NUM', 'OBJECT', 'PROPERTY');
		for(i = 1; i <= r.length; i++) {
			l = r[i].match;
			if(l.length < 1) {
				_logLine(toString(i), 'none', 'none');
			} else {
				for(j = 1; j <= l.length; j++) {
					_logLine(((j == 1) ? toString(i) : ''),
						toString(l[j].obj),
						toString(l[j].prop));
				}
			}
		}
		"</pre>";
		"\n<.p>\ntotal:  <<toString(r.length)>> instances\n ";
	}
;

class ModalRefcountDebugger: RefcountDebugger, DtkModalDebugger
	defaultCommands = static [
		RDRefcount, DtkCmdBack, DtkCmdHelp, DtkCmdHelpArg
	]
;

class RDRefcount: RDCmd 
	id = 'ref'
	help = 'display active references to class'
	longHelp = "Use <q>ref @CLASS</q> to display all of the objects and
		classes that contain references to instances of the
		argument class.
		<.p>Note that the argument has to start with an <q>@</q>. "
	argCount = 1
	cmd(cls) {
		local r;

		if(cls == nil) {
			output('missing class');
			return;
		}

		dtkRunGC();

		r = __refcountDebuggerEnumerator.searchEach(cls);
		_dtk.logResults(r);
	}
;

class DtkRefcount: DtkCommand
	id = 'refcount'
	help = 'switch to object reference mode'
	longHelp = "The <q>refcount</q> command switches to the modal
		object reference mode.  It is intened to help identifying
		references to dynamically-created objects. "

	_refcountDebugger = nil

	cmd() {
		if(_refcountDebugger == nil) {
			_refcountDebugger = new ModalRefcountDebugger();
			_refcountDebugger.addDefaultCommands();
		}
		_refcountDebugger.debugger(nil, nil, 'command line');
	}
;

#endif // DTK
