#charset "us-ascii"
//
// debugToolKit.t
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
