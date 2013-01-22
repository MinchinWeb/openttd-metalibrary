/*	Extra functions v.6 [2013-01-16],
 *		part of Minchinweb's MetaLibrary v.7,
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
 
// TO-DO:	Break this into Constants, Math, Geometry, and Extras
 
/*	These are 'random' functions that didn't seem to fit well elsewhere.
 *
 *	Functions provided:
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
 *		MinchinWeb.Extras.SignLocation(text)
 *						 .MidPoint(TileA, TileB)
 *						 .Perpendicular(SlopeIn)
 *						 .Slope(TileA, TileB)
 *						 .Within(Bound1, Bound2, Value)
 *						 .WithinFloat(Bound1, Bound2, Value)
 *						 .MinAbsFloat(Value1, Value2)
 *						 .MaxAbsFloat(Value1, Value2)
 *						 .AbsFloat(Value)
 *						 .Sign(Value)
 *						 .MinFloat(Value1, Value2)
 *						 .MaxFloat(Value1, Value2)
 *						 .MinAbsFloatKeepSign(Value1, Value2)
 *						 .MaxAbsFloatKeepSign(Value1, Value2)
 *						 .NextCardinalTile(StartTile, TowardsTile)
 *							- Given a StartTile and a TowardsTile, will given
 *								the tile immediately next(Manhattan Distance == 1)
 *								to StartTile that is closests to TowardsTile
 *						 .GetOpenTTDRevision()
 *							-Returns the revision number of the current build of OpenTTD
 *
 *	//	Comparision functions will return the first value if the two are equal
 *
 *		MinchinWeb.Industry.GetIndustryID(Tile)
 *								- AIIndustty.GetIndustryID( AIIndustry.GetLocation( IndustryID ) )
 *									sometimes fails because GetLocation() returns the northmost
 *									tile of the industry which may be a dock, heliport, or not
 *									part of the industry at all.
 *								- This function starts at the tile, and then searchs a square out
 *									(up to Constants.StationSize) until it finds a tile with a
 *									valid TileID.
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
	function BuoyOffset() { return 3; }				//	this is the assumed minimum desired spacing between bouys
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
 
class _MinchinWeb_Extras_ {
	_infinity = null;
	
	constructor()
	{
		this._infinity = _MinchinWeb_C_.Infinity();	
	}
	
}

function _MinchinWeb_Extras_::SignLocation(text)
{
//	Returns the tile of the first instance where the sign matches the given text
    local sign_list = AISignList();
    for (local i = sign_list.Begin(); !sign_list.IsEnd(); i = sign_list.Next()) {
        if(AISign.GetName(i) == text)
        {
            return AISign.GetLocation(i);
        }
    }
    return null;
}

function _MinchinWeb_Extras_::MidPoint(TileA, TileB)
{
//	Returns the tile that is halfway between the given tiles
	local X = (AIMap.GetTileX(TileA) + AIMap.GetTileX(TileB)) / 2 + 0.5;
	local Y = (AIMap.GetTileY(TileA) + AIMap.GetTileY(TileB)) / 2 + 0.5;
		//	the 0.5 is to make rounding work
	X = X.tointeger();
	Y = Y.tointeger();
	return AIMap.GetTileIndex(X, Y);
}

function _MinchinWeb_Extras_::Perpendicular(SlopeIn)
{
//	Returns the Perdicular slope, which is the inverse of the given slope
	if (SlopeIn == 0) {
		return this._infinity;
	} else {
		SlopeIn = SlopeIn.tofloat();
		return (-1 / SlopeIn);
	}
}

function _MinchinWeb_Extras_::Slope(TileA, TileB)
{
//	Returns the slope between two tiles
	local dx = AIMap.GetTileX(TileB) - AIMap.GetTileX(TileA);
	local dy = AIMap.GetTileY(TileB) - AIMap.GetTileY(TileA);
//	local Inftest = _MinchinWeb_Extras_._infinity;
//	AILog.Info(_MinchinWeb_Extras_._infinity);
	
	//	Zero check
	if (dx == 0) {
		return _MinchinWeb_C_.Infinity() * _MinchinWeb_Extras_.Sign(dy);
	} else if (dy == 0) {
		return (1.0 / _MinchinWeb_C_.Infinity()) * _MinchinWeb_Extras_.Sign(dx);
	} else {
		dx = dx.tofloat();
		dy = dy.tofloat();

		return (dy / dx);	
	}
}

function _MinchinWeb_Extras_::Within(Bound1, Bound2, Value)
{
	local UpperBound = max(Bound1, Bound2);
	local LowerBound = min(Bound1, Bound2);

	return ((Value <= UpperBound) && (Value >= LowerBound));
}

function _MinchinWeb_Extras_::WithinFloat(Bound1, Bound2, Value)
{
	local UpperBound = _MinchinWeb_Extras_.MaxFloat(Bound1, Bound2) + _MinchinWeb_C_.FloatOffset();
	local LowerBound = _MinchinWeb_Extras_.MinFloat(Bound1, Bound2) - _MinchinWeb_C_.FloatOffset();
	local Value = Value.tofloat();
	
//	_MinchinWeb_Log_.Note("          Extras.WithinFloat: Val=" + Value + " B1=" + Bound1 + " B2=" + Bound2 + " : UB=" + UpperBound + " LB=" + LowerBound + " is " + (Value <= UpperBound) + " " + (Value >= LowerBound) + " : " + ((Value <= UpperBound) && (Value >= LowerBound)) + " : above " + (Value - UpperBound) + " below " + (LowerBound - Value) + " : " + _MinchinWeb_C_.FloatOffset() , 7);

	return ((Value <= UpperBound) && (Value >= LowerBound));
}

function _MinchinWeb_Extras_::MinAbsFloat(Value1, Value2)
{
//	Takes the absolute value of both numbers and then returns the smaller of the two
	if (Value1 < 0) { Value1 *= -1.0; }
	if (Value2 < 0) { Value2 *= -1.0; }
	if (Value1 <= Value2) {
		return Value1;
	} else {
		return Value2;
	}
}

function _MinchinWeb_Extras_::MaxAbsFloat(Value1, Value2)
{
//	Takes the absolute value of both numbers and then returns the larger of the two
	if (Value1 < 0) { Value1 *= -1.0; }
	if (Value2 < 0) { Value2 *= -1.0; }
	if (Value1 >= Value2) {
		return Value1;
	} else {
		return Value2;
	}
}

function _MinchinWeb_Extras_::AbsFloat(Value)
{
//	Returns the absolute Value as a floating number if one is provided
	if (Value >= 0) {
		return Value;
	} else {
		return (Value * (-1.0));
	}
}

function _MinchinWeb_Extras_::Sign(Value)
{
//	Returns +1 if the Value >= 0, -1 Value < 0
	if (Value >= 0) {
		return 1;
	} else {
		return -1;
	}
}

function _MinchinWeb_Extras_::MinFloat(Value1, Value2)
{
//	Returns the smaller of the two
	if (Value1 <= Value2) {
		return (Value1).tofloat();
	} else {
		return (Value2).tofloat();
	}
}

function _MinchinWeb_Extras_::MaxFloat(Value1, Value2)
{
//	Returns the larger of the two
	if (Value1 >= Value2) {
		return (Value1).tofloat();
	} else {
		return (Value2).tofloat();
	}
}

function _MinchinWeb_Extras_::MinAbsFloatKeepSign(Value1, Value2)
{
//	Takes the absolute value of both numbers and then returns the smaller of the two
//	This keeps the sign when returning the value
	local Sign1 = _MinchinWeb_Extras_.Sign(Value1);
	local Sign2 = _MinchinWeb_Extras_.Sign(Value2);
	if (Value1 < 0) { Value1 *= -1.0; }
	if (Value2 < 0) { Value2 *= -1.0; }
	if (Value1 <= Value2) {
		return (Value1 * Sign1).tofloat();
	} else {
		return (Value2 * Sign2).tofloat();
	}
}

function _MinchinWeb_Extras_::MaxAbsFloatKeepSign(Value1, Value2)
{
//	Takes the absolute value of both numbers and then returns the larger of the two
//	This keeps the sign when returning the value
	local Sign1 = _MinchinWeb_Extras_.Sign(Value1);
	local Sign2 = _MinchinWeb_Extras_.Sign(Value2);
	if (Value1 < 0) { Value1 *= -1.0; }
	if (Value2 < 0) { Value2 *= -1.0; }
	if (Value1 >= Value2) {
		return (Value1 * Sign1).tofloat();
	} else {
		return (Value2 * Sign2).tofloat();
	}
}

function _MinchinWeb_Extras_::NextCardinalTile(StartTile, TowardsTile)
{
//	Given a StartTile and a TowardsTile, will given the tile immediately next
//		(Manhattan Distance == 1) to StartTile that is closests to TowardsTile
	local Tiles = AITileList();
	local offsets = [AIMap.GetTileIndex(0, 1), AIMap.GetTileIndex(0, -1),
						AIMap.GetTileIndex(1, 0), AIMap.GetTileIndex(-1, 0)];
				 
	foreach (offset in offsets) {
		Tiles.AddItem(StartTile + offset, AIMap.DistanceSquare(StartTile + offset, TowardsTile));
	}
	
	Tiles.Sort(AIList.SORT_BY_VALUE, AIList.SORT_ASCENDING);
	
	return Tiles.Begin();
}

function _MinchinWeb_Extras_::GetOpenTTDRevision()
{
//	Returns the revision number of the current build of OpenTTD

//	See AILib.Common for more details on what is contained in the full returned
//		version number

	local Version = AIController.GetVersion();
	local Revision = Version & 0x0007FFFF;
	return Revision;
}


// =============  INDUSTRY class  =============
class _MinchinWeb_Industry_ {
	main = null;
}

function _MinchinWeb_Industry_::GetIndustryID(Tile) {
//	AIIndustty.GetIndustryID( AIIndustry.GetLocation( IndustryID ) )  sometiles
//		fails because GetLocation() returns the northmost tile of the industry
//		which may be a dock, heliport, or not part of the industry at all.
//	This function starts at the tile, and then searchs a square out (up to
//		Constants.StationSize) until it finds a tile with a valid TileID.

	local StartX = AIMap.GetTileX(Tile);
	local StartY = AIMap.GetTileY(Tile);
	local EndX = AIMap.GetTileX(Tile) + _MinchinWeb_C_.IndustrySize();
	local EndY = AIMap.GetTileY(Tile) + _MinchinWeb_C_.IndustrySize();
	
	for (local i = StartX; i < EndX; i++) {
		for (local j = StartY; j < EndY; j++) {
			if (AIIndustry.GetIndustryID(AIMap.GetTileIndex(i,j)) != _MinchinWeb_C_.InvalidIndustry()) {
				return AIIndustry.GetIndustryID(AIMap.GetTileIndex(i,j));
			}
		}
	}
	
	//	if no valid industry is found...
	return _MinchinWeb_C_.InvalidIndustry();
}

// =============  ROAD class  =============
class _MinchinWeb_Road_ {
	main = null;
}

