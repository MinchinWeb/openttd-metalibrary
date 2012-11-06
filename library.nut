/*	Minchinweb's MetaLibrary v.4 r.227 [2012-01-30],  
 *	Copyright © 2011-12 by W. Minchin. For more info,
 *		please visit http://openttd-noai-wmdot.googlecode.com/
 */

class MinchinWeb extends AILibrary {
	function GetAuthor()      { return "W. Minchin"; }
	function GetName()        { return "MinchinWeb"; }
	function GetShortName()   { return "LMmW"; }	//	William's MetaLibrary
	function GetDescription() { return "Minchinweb's MetaLibrary for AI development. See the README for included functions. (v.4, r.227) [2012-01-30]"; }
	function GetVersion()     { return 4; }
	function GetDate()        { return "2012-01-30"; }
	function CreateInstance() { return "MinchinWeb"; }
	function GetCategory()    { return "Util"; }
//	function GetURL()		  { return "http://www.tt-forums.net/viewtopic.php?f=65&t=57903"; }
//	function GetAPIVersion()  { return "1.1"; }
	function MinVersionToLoad() { return 1; }
}

RegisterLibrary(MinchinWeb());

//	requires AyStar v6
//	requires Fibonacci Heap v2
