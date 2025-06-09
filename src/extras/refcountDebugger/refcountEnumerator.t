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

#endif // DTK
