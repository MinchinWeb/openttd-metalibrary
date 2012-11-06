/*	Extra functions v.1 r.109 [2011-04-23],
 *	part of Minchinweb's MetaLibrary v1, r109, [2011-04-23],
 *	originally part of WmDOT v.6
 *	Copyright © 2011 by W. Minchin. For more info,
 *		please visit http://openttd-noai-wmdot.googlecode.com/
 */
 
/*	These are 'random' functions that didn't seem to fit well elsewhere.
 *
 *	Functions provided:
 *		MetaLib.Extras.DistanceShip(TileA, TileB)
 *					  .SignLocation(text)
 *					  .MidPoint(TileA, TileB)
 *					  .Perpendicular(SlopeIn)
 *					  .Slope(TileA, TileB)
 *					  .Within(Bound1, Bound2, Value)
 *					  .WithinFloat(Bound1, Bound2, Value)
 *					  .MinAbsFloat(Value1, Value2)
 *					  .MaxAbsFloat(Value1, Value2)
 *					  .AbsFloat(Value)
 *					  .Sign(Value)
 *					  .MinFloat(Value1, Value2)
 *					  .MaxFloat(Value1, Value2)
 *					  .MinAbsFloatKeepSign(Value1, Value2)
 *					  .MaxAbsFloatKeepSign(Value1, Value2)
 *	//	Comparision functions will return the first value if the two are equal
 */
 
class _MetaLib_Extras_ {
	_infinity = null;
	
	constructor()
	{
		this._infinity = 10000;	//	close enough to infinity :P
								//	Slopes are capped at 10,000 and 1/10,000
	}
	
}

function _MetaLib_Extras_::DistanceShip(TileA, TileB)
{
//	Assuming open ocean, ship in OpenTTD will travel 45° angle where possible,
//		and then finish up the trip by going along a cardinal direction
	return ((AIMap.DistanceManhattan(TileA, TileB) - AIMap.DistanceMax(TileA, TileB)) * 0.4 + AIMap.DistanceMax(TileA, TileB))
}

function _MetaLib_Extras_::SignLocation(text)
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

function _MetaLib_Extras_::MidPoint(TileA, TileB)
{
//	Returns the tile that is halfway between the given tiles
	local X = (AIMap.GetTileX(TileA) + AIMap.GetTileX(TileB)) / 2 + 0.5;
	local Y = (AIMap.GetTileY(TileA) + AIMap.GetTileY(TileB)) / 2 + 0.5;
		//	the 0.5 is to make rounding work
	X = X.tointeger();
	Y = Y.tointeger();
	return AIMap.GetTileIndex(X, Y);
}

function _MetaLib_Extras_::Perpendicular(SlopeIn)
{
//	Returns the Perdicular slope, which is the inverse of the given slope
	if (SlopeIn == 0) {
		return this._infinity;
	} else {
		SlopeIn = SlopeIn.tofloat();
		return (-1 / SlopeIn);
	}
}

function _MetaLib_Extras_::Slope(TileA, TileB, Infinity = _MetaLib_Extras_._infinity)
{
//	Returns the slope between two tiles
	local dx = AIMap.GetTileX(TileB) - AIMap.GetTileX(TileA);
	local dy = AIMap.GetTileY(TileB) - AIMap.GetTileY(TileA);
	local Inftest = _MetaLib_Extras_._infinity;
//	AILog.Info(_MetaLib_Extras_._infinity);
	
	//	Zero check
	if (dx == 0) {
		return Infinity * _MetaLib_Extras_.Sign(dy);
	} else if (dy == 0) {
		return (1.0 / Infinity) * _MetaLib_Extras_.Sign(dx);
	} else {
		dx = dx.tofloat();
		dy = dy.tofloat();

		return (dx / dy);	
	}
}

function _MetaLib_Extras_::Within(Bound1, Bound2, Value)
{
	local UpperBound = max(Bound1, Bound2);
	local LowerBound = min(Bound1, Bound2);

	return ((Value <= UpperBound) && (Value >= LowerBound));
}

function _MetaLib_Extras_::WithinFloat(Bound1, Bound2, Value)
{
	local UpperBound = _MetaLib_Extras_.MaxFloat(Bound1, Bound2);
	local LowerBound = _MetaLib_Extras_.MinFloat(Bound1, Bound2);
//	local Value = Value.tofloat();
	
//	AILog.Info("          Extras.WithinFloat: Val=" + Value + " B1=" + Bound1 + " B2=" + Bound2 + " : UB=" + UpperBound + " LB=" + LowerBound + " is " + (Value <= UpperBound) + " " + (Value >= LowerBound) + " : " + ((Value <= UpperBound) && (Value >= LowerBound)))

	return ((Value <= UpperBound) && (Value >= LowerBound));
}

function _MetaLib_Extras_::MinAbsFloat(Value1, Value2)
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

function _MetaLib_Extras_::MaxAbsFloat(Value1, Value2)
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

function _MetaLib_Extras_::AbsFloat(Value)
{
//	Returns the absolute Value as a floating number if one is provided
	if (Value >= 0) {
		return Value;
	} else {
		return (Value * (-1.0));
	}
}

function _MetaLib_Extras_::Sign(Value)
{
//	Returns +1 if the Value >= 0, -1 Value < 0
	if (Value >= 0) {
		return 1;
	} else {
		return -1;
	}
}

function _MetaLib_Extras_::MinFloat(Value1, Value2)
{
//	Returns the smaller of the two
	if (Value1 <= Value2) {
		return (Value1).tofloat();
	} else {
		return (Value2).tofloat();
	}
}

function _MetaLib_Extras_::MaxFloat(Value1, Value2)
{
//	Returns the larger of the two
	if (Value1 >= Value2) {
		return (Value1).tofloat();
	} else {
		return (Value2).tofloat();
	}
}

function _MetaLib_Extras_::MinAbsFloatKeepSign(Value1, Value2)
{
//	Takes the absolute value of both numbers and then returns the smaller of the two
//	This keeps the sign when returning the value
	local Sign1 = _MetaLib_Extras_.Sign(Value1);
	local Sign2 = _MetaLib_Extras_.Sign(Value2);
	if (Value1 < 0) { Value1 *= -1.0; }
	if (Value2 < 0) { Value2 *= -1.0; }
	if (Value1 <= Value2) {
		return (Value1 * Sign1).tofloat();
	} else {
		return (Value2 * Sign2).tofloat();
	}
}

function _MetaLib_Extras_::MaxAbsFloatKeepSign(Value1, Value2)
{
//	Takes the absolute value of both numbers and then returns the larger of the two
//	This keeps the sign when returning the value
	local Sign1 = _MetaLib_Extras_.Sign(Value1);
	local Sign2 = _MetaLib_Extras_.Sign(Value2);
	if (Value1 < 0) { Value1 *= -1.0; }
	if (Value2 < 0) { Value2 *= -1.0; }
	if (Value1 >= Value2) {
		return (Value1 * Sign1).tofloat();
	} else {
		return (Value2 * Sign2).tofloat();
	}
}