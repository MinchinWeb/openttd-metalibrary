/*	Minchinweb's MetaLibrary v.6 [2012-12-24],  
 *		originally part of WmDOT v.10
 *	Copyright © 2011-12 by W. Minchin. For more info,
 *		please visit https://github.com/MinchinWeb/openttd-metalibrary
 *
 *	Permission is granted to you to use, copy, modify, merge, publish, 
 *	distribute, sublincense, and/or sell this software, and provide these 
 *	rights to others, provided:
 *
 *	+ The above copyright notice and this permission notice shall be included
 *		in all copies or substantial portions of the software.
 *	+ Attribution is provided in the normal place for recognition of 3rd party
 *		contributions.
 *	+ You accept that this software is provided to you "as is", without warranty.
 */

class MinchinWeb extends AILibrary {
	function GetAuthor()      { return "W. Minchin"; }
	function GetName()        { return "MinchinWeb"; }
	function GetShortName()   { return "LMmW"; }	//	William's MetaLibrary
	function GetDescription() { return "Minchinweb's MetaLibrary for AI development. See the README for included functions. (v.6, 2012-12-24)"; }
	function GetVersion()     { return 6; }
	function GetDate()        { return "2012-06-27"; }
	function CreateInstance() { return "MinchinWeb"; }
	function GetCategory()    { return "Util"; }
//	function GetURL()		  { return "http://www.tt-forums.net/viewtopic.php?f=65&t=57903"; }
//	function GetAPIVersion()  { return "1.2"; }
	function MinVersionToLoad() { return 1; }
}

RegisterLibrary(MinchinWeb());

//	requires AyStar v6
//	requires Fibonacci Heap v2
