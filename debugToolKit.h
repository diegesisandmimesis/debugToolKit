//
// debugToolKit.h
//

#ifdef DTK

#define DefineDtkAction(name, kw, debuggerObj...) \
	VerbRule(name) kw: name##Action; \
	class name##Action: DtkDebuggerAction \
	baseActionClass = name##Action \
	_debugger = debuggerObj

#else // DTK

#define DefineDtkAction(name, kw, debuggerObj...)

#endif // DTK

DtkCommand template 'id' +argCount? 'help'? "longHelp"?;

#define DEBUG_TOOL_KIT_H
