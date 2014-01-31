/*	Constants for MetaLibrary v.5 r.253 [2011-07-01],
 *		part of Minchinweb's MetaLibrary v.6,
 *		originally part of WmDOT v.10
 *	Copyright © 2011-14 by W. Minchin. For more info,
 *		please visit https://github.com/MinchinWeb/openttd-metalibrary
 *
 *	Permission is granted to you to use, copy, modify, merge, publish, 
 *	distribute, sublicense, and/or sell this software, and provide these 
 *	rights to others, provided:
 *
 *	+ The above copyright notice and this permission notice shall be included
 *		in all copies or substantial portions of the software.
 *	+ Attribution is provided in the normal place for recognition of 3rd party
 *		contributions.
 *	+ You accept that this software is provided to you "as is", without warranty.
 */
 
/*	Functions provided:
 *		MinchinWeb.Constants.Infinity() - returns 10,000
 *							.FloatOffset() - returns 1/2000
 *							.Pi() - returns 3.1415...
 *							.e() - returns 2.7182...
 *							.IndustrySize() - returns 4
 *							.InvalidIndustry() - returns 0xFFFF (65535)
 *							.InvalidTile() - returns 0xFFFFFF
 *							.MaxStationSpread() - returns the maximum station spread
 *							.BuoyOffset() - returns 3
 *							.WaterDepotOffset() - return 4
 *						
 */

class _MinchinWeb_C_ {
	//	These are constants called by the various sublibraries
	function Infinity() 	{ return 10000; }	//	close enough to infinity :P
												//	Slopes are capped at 10,000 and 1/10,000
	function FloatOffset()	{ return 0.0005; }	//	= 1/2000
	
	function Pi() { return 3.1415926535897932384626433832795; }
	function e() { return 2.7182818284590452353602874713527; }
	
	function IndustrySize() { return 4; }	//	Industries are assumed to fit 
											//		within a 4x4 box
	function InvalidIndustry() { return 0xFFFF; }	//	number returned by OpenTTD for an invalid industry (65535)
	function InvalidTile() { return 0xFFFFFF; } 	//	a number beyond the a valid TileIndex
													//	valid (or invalid, if you prefer) for at least up to 2048x2048 maps
	function BuoyOffset() { return 3; }				//	this is the assumed minimum desired spacing between buoys
	function WaterDepotOffset() { return 4; }		//	this is the maximum desired spacing between docks and depots
	
	function MaxStationSpread() {
	//	returns the OpenTTD setting for maximum station spread
		if(AIGameSettings.IsValid("station_spread")) {
			return AIGameSettings.GetValue("station_spread");
		} else {
			try {
			AILog.Error("'station_spread' is no longer valid! (MinchinWeb.Constants.MaxStationSpread(), v." + this.GetVersion() + " r." + this.GetRevision() + ")");
			AILog.Error("Please report this problem to http://www.tt-forums.net/viewtopic.php?f=65&t=57903");
			} catch (idx) {
			}
			return 16;
		}
	}
}
