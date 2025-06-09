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

__refcountDebuggerEnumerator: object
	_classHeads = static [
		Thing
	]

	searchEach(cls) {
		local r;

		r = new Vector();
		forEachInstance(cls, function(x) {
			r.append(new _DtkSearchResult(x,
				search({ y: x.__equals(y) })));
		});
		return(r);
	}
	search(fn) {
		local obj, r, v;

		if(!_isFunction(fn))
			return([]);
		r = new Vector();

		obj = firstObj();
		while(obj) {
			if((v = _searchObject(obj, fn)) != nil)
				r.append(new _DtkObjMatch(obj, v));
			obj = nextObj(obj);
		}

		_classHeads.forEach(function(x) {
			obj = firstObj(x, ObjClasses);
			while(obj) {
				if((v = _searchObject(obj, fn)) != nil)
					r.append(new _DtkObjMatch(obj, v));
				obj = nextObj(obj, ObjClasses);
			}
		});

		return(r);
	}

	_searchObject(obj, fn) {
		local i, l, r;

		l = obj.getPropList();
		for(i = 1; i <= l.length; i++) {
			//if(!obj.propDefined(l[i], PropDefDirectly))
				//continue;
			if(!obj.propDefined(l[i]))
				continue;
			if((r = _searchObjectProp(obj, fn, l[i])) != nil)
				return(r);
		}

		return(nil);
	}

	_searchObjectProp(obj, fn, x) {
		switch(obj.propType(x)) {
			case TypeList:
				return(_searchObjectList(obj, fn, x));
			case TypeObject:
				return(_searchObjectObject(obj, fn, x));
		}

		return(nil);
	}

	_searchObjectList(obj, fn, x) {
		if(fn(obj.(x)) == true) return(x);
		return(nil);
	}

	_searchObjectObject(obj, fn, x) {
		local v;

		v = (obj).(x);
		if(_isLookupTable(v)) {
			return(_searchTypeLookupTable(obj, fn, x));
		}
		if(_isCollection(v)) {
			return(_searchTypeCollection(obj, fn, x));
		}
		if(_isObject(v)) {
			return(_searchTypeObject(obj, fn, x));
		}

		return(nil);
	}

	_searchTypeLookupTable(obj, fn, x) {
		if(_checkLookupTable(obj.(x), fn))
			return(x);

		return(nil);
	}

	_searchTypeCollection(obj, fn, x) {
		if(_checkCollection(obj.(x), fn))
			return(x);
		return(nil);
	}

	_searchTypeObject(obj, fn, x) {
		if(_checkObject(obj.(x), fn))
			return(x);
		return(nil);
	}

	_checkValue(v, fn) {
		if((dataType(v) != TypeObject) && (dataType(v) != TypeList))
			return(nil);
		if(_isLookupTable(v)) {
			return(_checkLookupTable(v, fn));
		}
		if(_isCollection(v)) {
			return(_checkCollection(v, fn));
		}
		if(_isObject(v)) {
			return(_checkObject(v, fn));
		}
		return(nil);
	}

	_checkObject(v, fn) {
		if(dataType(v) != TypeObject)
			return(nil);
		if(fn(v) == true)
			return(true);
		return(nil);
	}
	_checkCollection(v, fn) {
		v = v.subset({ x: dataType(x) == TypeObject });
		if(v == nil) return(nil);
		if(v.valWhich({ x: _checkValue(x, fn) == true }) != nil)
			return(true);
		return(nil);
	}

	_checkLookupTable(v, fn) {
		local i, k, l;

		l = v.keysToList();
		if(l == nil) return(nil);
		for(i = 1; i <= l.length; i++) {
			k = l[i];
			if(_checkValue((k), fn))
				return(true);
			if(_checkValue(v[k], fn))
				return(true);
		}
		return(nil);
	}

	forEachObject(fn?) {
		local obj;

		if(!_isFunction(fn))
			return;
		obj = firstObj();
		while(obj) {
			fn(obj);
			obj = nextObj(obj);
		}
	}
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
			l = r[1].match;
			if(l.length < 1) {
				_logLine(toString(i), 'none', 'none');
				continue;
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
;

class RDRefcount: RDCmd 
	id = 'ref'
	help = 'display active references to class'
	longHelp = "Use <q>ref</q> to display all of the objects and
		classes that contain references to instances of the
		argument class. "
	argCount = 1
	cmd(cls) {
		local r;

		if(cls == nil) {
			output('missing class');
			return;
		}

		r = __refcountDebuggerEnumerator.searchEach(cls);
		_dtk.logResults(r);
	}
;

#endif // DTK
