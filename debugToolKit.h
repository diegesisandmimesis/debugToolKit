//
// debugToolKit.h
//

#define DefineDtkDebuggerAction(name, debuggerObj...) \
	class name##Action: DtkDebuggerAction \
	baseActionClass = name##Action \
	_debugger = debuggerObj
	

DtkCommand template 'id' 'help'? "longHelp"?;

#define DEBUG_TOOL_KIT_H
