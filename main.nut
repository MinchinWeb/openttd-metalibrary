/*	Minchinweb's MetaLibrary v.6-GS [2012-12-31],  
 *		originally part of, WmDOT v.10
 *	Copyright © 2011-13 by W. Minchin. For more info,
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
 
/*	See the README for a list of the functions included in this library.
 */
 
/*	Q:	What is MinchinWeb's MetaLibrary?
 *	A:	MetaLib is the collection of code I've written for WmDOT, my AI for
 *			OpenTTD, that I felt should properly be in a library. I also hope
 *			will this code will help some aspiring AI/GS writer get off the ground
 *			a little bit faster. ;)
 *
 *	Q:	How do I use the sublibraries directly?
 *	A:	Import the main library, and then create global points to the
 *			sublibaries you want to use. Eg:
 *		
 *			Import("util.MinchinWeb", "MinchinWeb", 5);
 *			Arrays <- MinchinWeb.Arrays;
 *
 *	Info:	See the sub-library files for the functions available and their
 *				implementation.
 *
 *	Q:	What is the _MinchinWeb_... all over the place?
 *	A:	I can't answer it better than Zuu when he put together his SuperLib, so
 *			I'll quote him.
 *
 *		  "	Unfortunately due to constraints in OpenTTD and Squirrel, only the
 *			main class of a library will be renamed at import. For [MetaLib]
 *			that is the [MetaLib] class in this file. Every other class in this
 *			file or other .nut files that the library is built up by will end
 *			up at the global scope at the GS that imports the library. The
 *			global scope of the library will get merged with the global scope
 *			of your GS.
 *
 *		  "	To reduce the risk of causing you conflict problems this library
 *			prefixes everything that ends up at the global scope of GSs with
 *			[ _MinchinWeb_ ]. That is also why the library is not named Utils or
 *			something with higher risk of you already having at your global
 *			scope.
 *
 *		  "	You should however never need to use any of the [ _MinchinWeb_... ]
 *			names as a user of this library. It is not even recommended to do
 *			so as it is part of the implementation and could change without
 *			notice. "
 *											- Zuu, SuperLib v7 documentation
 *
 *	A grand 'Thank You' to Zuu for his SuperLib that provided a very useful
 *		model, to all the NoAI team to their work on making the GS system work,
 *		and to everyone that has brought us the amazing game of OpenTTD.
 */
 
require("Pathfinder.Road.nut");
	//	Requires Graph.AyStar v6 library
// require("AyStar.WM.nut");
require("Arrays.nut");
// require("Fibonacci.Heap.WM.nut");
require("Extras.nut");
require("Waterbody.Check.nut");
require("Pathfinder.Ship.nut");
require("Line.Walker.nut");
require("Spiral.Walker.nut");
require("Atlas.nut");
require("Marine.nut");
require("Log.nut");
require("Dominion.Roads.nut")

class MinchinWeb {
	function GetVersion()       { return 6; }
	function GetRevision()		{ return 121231; }
	function GetDate()          { return "2012-12-31"; }
	function GetName()          { return "MinchinWeb's MetaLibrary"; }

	static RoadPathfinder = _MinchinWeb_RoadPathfinder_;
	static ShipPathfinder = _MinchinWeb_ShipPathfinder_;	
	static Array = _MinchinWeb_Array_;
	static Extras = _MinchinWeb_Extras_;
	static WaterbodyCheck = _MinchinWeb_WBC_;
	static LineWalker = _MinchinWeb_LW_;
	static SpiralWalker = _MinchinWeb_SW_;
	static Constants = _MinchinWeb_C_;			// in Extras.nut
	static Atlas = _MinchinWeb_Atlas_;
	static Marine = _MinchinWeb_Marine_;
	static Industry = _MinchinWeb_Industry_;	// in Extras.nut
	static Station = _MinchinWeb_Station_;		// in Extras.nut
	static Log = _MinchinWeb_Log_;
	static DLS = _MinchinWeb_DLS_;				// in Dominion.Roads.nut
}
 