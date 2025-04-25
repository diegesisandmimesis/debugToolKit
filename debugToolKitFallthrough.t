#charset "us-ascii"
//
// debugToolKitFallthrough.t
//
//	Placeholder definitions for when the module/game is compiled without
//	the -D DTK flag.
//
//
#include <adv3.h>
#include <en_us.h>

#include "debugToolKit.h"

#ifndef DTK

class DtkOutputStream: object;
class DtkParseResult: object;
class DtkDebuggerAction: object debugger() {};
class DtkDebugger: object transcript = nil spacer = nil;
class DtkObject: object
	_dtk = nil output() {} getDebugger() {} setDebugger() {};
class DtkCommand: DtkObject;
class DtkEval: object;

#endif // DTK
