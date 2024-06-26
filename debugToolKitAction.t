#charset "us-ascii"
//
// debugToolKitAction.t
//
#include <adv3.h>
#include <en_us.h>

#include "debugToolKit.h"

#ifdef DTK

modify playerActionMessages
	dtkNoDebugger = 'No debugger defined. '
;

class DtkDebuggerAction: SystemAction
	_debugger = nil
	execSystemAction() {
		if(_debugger == nil) {
			reportFailure(&dtkNoDebugger);
			exit;
		}
		startDebugger(_debugger);

		// Needed to avoid a "Nothing obvious happens".
		defaultReport(' ');
	}

	startDebugger(obj) { obj.debugger(nil, nil, 'command line'); }
;

DefineTAction(DtkScope) objInScope(obj) { return(true); };
VerbRule(DtkScope) 'dtkscope' singleDobj: DtkScopeAction;

#endif // DTK
