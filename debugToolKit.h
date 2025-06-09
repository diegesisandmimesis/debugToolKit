//
// debugToolKit.h
//

#ifdef DTK

#define DefineDtkAction(name, kw, debuggerObj...) \
	VerbRule(name) kw: name##Action; \
	class name##Action: DtkDebuggerAction \
	baseActionClass = name##Action \
	_debugger = debuggerObj \

#else // DTK

#define DefineDtkAction(name, kw, debuggerObj...)

#endif // DTK

DtkCommand template 'id' +argCount? 'help'? "longHelp"?;
DtkCommand template 'id' +argCount? 'usage'? 'help'? "longHelp"?;

#ifndef isNumber
#define isNumber(x) (rexMatch('^<space>*(<Digit>+)<space>*$', x) != nil)
#endif // isNumber

// Datatype testing macros.  Defined so we don't have to require
// the dataTypes module.
#ifndef _isType
#define _isType(v, cls) ((v != nil) && (dataType(v) == TypeObject) && v.ofKind(cls))
#endif
#ifndef _isIntrinsicType
#define _isIntrinsicType(v, cls) ((v != nil) && v.ofKind(cls))
#endif
#ifndef _isLookupTable
#define _isLookupTable(v) (_isType(v, LookupTable))
#endif
#ifndef _isObject
#define _isObject(v) ((v != nil) && (dataType(v) == TypeObject))
#endif
#ifndef _isCollection
#define _isCollection(v) (_isIntrinsicType(v, Collection))
#endif
#ifndef _isFunction
#define _isFunction(obj) ((dataType(obj) != TypeNil) && ( \
	((dataType(obj) == TypeProp) && ((propType(obj) == TypeFuncPtr) \
		|| (propType(obj) == TypeCode))) \
	|| (dataTypeXlat(obj) == TypeFuncPtr) \
))
#endif

#define DEBUG_TOOL_KIT_H
