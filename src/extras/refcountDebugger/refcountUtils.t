#charset "us-ascii"
//
// refcountUtils.t
//
//
#include <adv3.h>
#include <en_us.h>
#include <dynfunc.h>

#include "debugToolKit.h"

#ifdef DTK


function __metaGC(fn?) {
	local s;

	t3RunGC();

	fn = (fn ? fn : 'metaGCSave');

	PreSaveObject.classExec();
	try { saveGame(fn, gameMain.getSaveDesc('metaGC savefile')); }
	catch(Exception e) { return(nil); }
	try { restoreGame(fn); }
	catch(Exception e) { return(nil); }
	PostRestoreObject.restoreCode = 2;
	PostRestoreObject.classExec();

	return(true);
}

#endif // DTK
