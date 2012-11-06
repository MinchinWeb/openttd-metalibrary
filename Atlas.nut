/*	Atlas v.1 r.221 [2012-01-28],
 *		part of Minchinweb's MetaLibrary v.4,
 *	Copyright © 2011-12 by W. Minchin. For more info,
 *		please visit http://openttd-noai-wmdot.googlecode.com/
 */
 
/*	The Atlas takes sources (departs) and attractions (destinations) and then
 *		generates a heap of pairs sorted by rating. Ratings can be generated
 *		based on distance alone or can be altered by user defined ratings (e.g.
 *		industry productions or town populations).
 */
 
/*
 *	Included functions:
 
	Atlas()
	Atlas.Reset()
			- Resets the Atlas (dumps all entered data)
		.AddSource(Source, Priority)
			- Adds a source to the sources list with the given priority
			- Assumes Source to be a TileIndex
		.AddAttraction(Attraction, Priority)
			- Adds an attraction to the attraction list with the given priority
			- Assumes Source to be a TileIndex
		.AddBoth(AddedTile, Priority)
			- Adds a tile to the BOTH the sources list and the attractions
				list with the (same) given priority
		.RunModel()
			- Takes the provided sources and destinations and runs the
				selected traffic model, populating the 'pairs' heap
		.Pop()
			- Returns the top rated pair as an array and removes the pair from
				the model
		.Peek()
			- Returns the top rated pair (as an array) but DOES NOT remove the
				pair from the model
		.Count()
			- Returns the amount of items currently in the list.
		.Exists
			- Check if an item exists in the list. Returns true/false.
		.SetModel(newmodel)
			- Sets the model type to the provided type
		.GetModel()
			- Returns the current model type (as the enum)
		.PrintModelType(ToPrint)
			- given a ModelType, returns the string equivalent
		.ApplyTrafficModel(StartTile, StartPriority, EndTile, EndPriority,
				Model)
			- Given the start and end points, applies the traffic model and
				returns the weighting (Smaller weightings are considered better)
			- This function is indepedant of the model/class, so is useful if
				you want to apply the traffic model to a given set of points. It
				is what is called internally to apply the model
		.SetMaxDistance(distance = -1)
			- Sets the maximum distance between sources and attractions to be
				included in the model
			- Negative values remove the limit
		.SetMaxDistanceModel(newmodel)
			- Sets the model type to the provided type
			- Used to calculate the distance between the source and attraction
				for applying maxdistance
			- DISTANCE_NONE is invalid. Use MinchinWeb.Atlas.SetMaxDistance(-1)
				instead.
			- ONE_OVER_T_SQUARED is invalid.



 */

 
enum ModelType
{
	ONE_D,					// 0
	DISTANCE_MANHATTAN,		// 1
	DISTANCE_SHIP,			// 2
	DISTANCE_AIR,			// 3
	DISTANCE_NONE,			// 4
	ONE_OVER_T_SQUARED,		// 5
}
 
class _MinchinWeb_Atlas_ {
	function GetVersion()       { return 1; }
	function GetRevision()		{ return 187; }
	function GetDate()          { return "2012-01-04"; }
	function GetName()          { return "Atlas Library"; }

	_heap_class = import("Queue.Binary_Heap", "", 1);
	
	_sources = [];			//	'from' here... (array)
	_attractions = [];		//		'to' here  (array)
	_pairs = null;			//	heap of paired sources and attractions
	
	_ignorepairs = [];		//	a list of pairs to ignore
	_maxdistance = null;	//	this is the maximum distance between sources and attractions to include in the model
	_maxdistancemodel = null;	//	this is how to measure distances between sources and attractions to determine weather they exceed "_maxdistance"
		
	
	_model = null;			//	enumerated list of possible models
	
	constructor()
	{
		this._pairs = this._heap_class();
		this._model = ModelType.DISTANCE_MANHATTAN;
		this._ignorepairs = [[-1,-1]];
		this._maxdistance = -1;
		this._maxdistancemodel = ModelType.DISTANCE_MANHATTAN;
		this._model = 1;
	}
}

function _MinchinWeb_Atlas_::Reset()
{
//	Resets the Atlas
	this._pairs = this._heap_class();
	this._model = ModelType.DISTANCE_MANHATTAN;
	this._ignorepairs = [[-1,-1]];
	this._maxdistance = -1;
	this._sources = [];
	this._attractions = [];
	this._maxdistancemodel = ModelType.DISTANCE_MANHATTAN;
	return;
}

function _MinchinWeb_Atlas_::AddSource(Source, Priority)
{
//	Adds a source to the sources list with the given priority
//	Assumes Source to be a TileIndex
	this._sources.push([Source, Priority]);
}

function _MinchinWeb_Atlas_::AddAttraction(Attraction, Priority)
{
//	Adds an attraction to the attraction list with the given priority
	this._attractions.push([Attraction, Priority]);
}

function _MinchinWeb_Atlas_::AddBoth(AddedTile, Priority)
{
//	Adds a tile to the BOTH the sources list and the attractions list with the (same) given priority
	this._sources.push([AddedTile, Priority]);
	this._attractions.push([AddedTile, Priority]);
}

function _MinchinWeb_Atlas_::RunModel()
{
//	Takes the provided sources and destinations and runs the selected traffic model, populating the 'pairs' heap
	this._pairs = this._heap_class();
	for (local i = 0; i < this._sources.len(); i++) {
		_MinchinWeb_Log_.Note("          i = " + i, 7);
		for (local j = 0; j < this._attractions.len(); j++) {
			_MinchinWeb_Log_.Note("               j = " + j + "     " + (_MinchinWeb_Array_.ContainedIn1D([this._sources[i][0], this._attractions[j][0]], this._ignorepairs) == false) + "; " + _MinchinWeb_Atlas_.ApplyTrafficModel(this._sources[i][0], 1, this._attractions[j][0], 0, this._maxdistancemodel) + " < " +	this._maxdistance + " = " + ((_MinchinWeb_Atlas_.ApplyTrafficModel(this._sources[i][0], 1, this._attractions[j][0], 0, this._maxdistancemodel) < this._maxdistance)	|| (this._maxdistance < 0)) + " ;; " + _MinchinWeb_Array_.ToStringTiles1D([this._sources[i][0]]) + " - " + this._sources[i][1] + "  " + _MinchinWeb_Array_.ToStringTiles1D([this._attractions[j][0]]) + " - " + this._attractions[j][1] + " -- " + this._model + " :: " + AIMap.DistanceManhattan(this._sources[i][0], this._attractions[j][0]) + " / (" + this._sources[i][1] + " + " + this._attractions[j][1] + ") = " + (AIMap.DistanceManhattan(this._sources[i][0], this._attractions[j][0]) / (this._sources[i][1].tofloat() + this._attractions[j][1].tofloat())) + " : " + _MinchinWeb_Atlas_.ApplyTrafficModel(this._sources[i][0], this._sources[i][1], this._attractions[j][0], this._attractions[j][1], this._model), 7);
			if ((_MinchinWeb_Array_.ContainedIn1D([this._sources[i][0], this._attractions[j][0]], this._ignorepairs) == false)
					&& ((_MinchinWeb_Atlas_.ApplyTrafficModel(this._sources[i][0], 1, this._attractions[j][0], 0, this._maxdistancemodel) < this._maxdistance)
					|| (this._maxdistance < 0))) {
				this._pairs.Insert([this._sources[i][0], this._attractions[j][0]],
						_MinchinWeb_Atlas_.ApplyTrafficModel(this._sources[i][0], this._sources[i][1], this._attractions[j][0], this._attractions[j][1], this._model));
			}
		}
	}
}

function _MinchinWeb_Atlas_::Pop()
{
//	Returns the top rated pair as an array and removes the pair from the model

//	If the two tiles returned are equal, pop another one
	local KeepTrying = true;
	local Test;
	while (KeepTrying == true) {
		Test = this._pairs.Pop();
		if ((Test == null) || (Test[0] != Test[1])) {
			KeepTrying = false;
		}
	}
	return Test;
}

function _MinchinWeb_Atlas_::Peek()
{
//	Returns the top rated pair (as an array) but DOES NOT remove the pair from the model
	return this._pairs.Peek();
}

function _MinchinWeb_Atlas_::Count()
{
//	Returns the amount of items currently in the list.
	return this._pairs.Count();
}

function _MinchinWeb_Atlas_::Exists()
{
//	Check if an item exists in the list. Returns true/false.
	return this._pairs.Exists();
}

function _MinchinWeb_Atlas_::SetModel(newmodel)
{
//	Sets the model type to the provided type
	if ((newmodel == ModelType.ONE_D) || (newmodel == ModelType.DISTANCE_MANHATTAN) || (newmodel == ModelType.DISTANCE_SHIP) ||
			(newmodel == ModelType.DISTANCE_AIR) || (newmodel == ModelType.DISTANCE_NONE) || (newmodel == ModelType.ONE_OVER_T_SQUARED)) {
		this._model = newmodel;
	} else {
		AILog.Warning("MinchinWeb.Atlas.SetModel() was supplied with an invalide ModelType. Was supplied: " + newmodel ".");
	}
}

function _MinchinWeb_Atlas_::GetModel()
{
//	Returns the current model type (as the enum)
	return this._model;
}

function _MinchinWeb_Atlas_::PrintModelType(ToPrint)
{
//	given a ModelType, returns the string equivalent
	
	switch (ToPrint) {
		case ModelType.ONE_D :
			return "1-D";
			break;
		case ModelType.DISTANCE_MANHATTAN :
			return "Distance Manhattan";
			break;
		case ModelType.DISTANCE_SHIP :
			return "Distance Ship";
			break;
		case ModelType.DISTANCE_AIR :
			return "Distance Air";
			break;
		case ModelType.DISTANCE_NONE :
			return "Distance Disregarded";
			break;
		case ModelType.ONE_OVER_T_SQUARED :
			return "1/t^2";
			break;
		default:
			return "ERROR: Bad ModelType. Supplied " + ToPrint;
			break;
	}
}


function _MinchinWeb_Atlas_::ApplyTrafficModel(StartTile, StartPriority, EndTile, EndPriority, Model)
{
//	Given the start and end points, applies the traffic model and returns the
//		weighting
//	Smaller weightings are considered better

	switch (Model) {
		case ModelType.ONE_D :
			return AIMap.DistanceMax(StartTile, EndTile) / (StartPriority.tofloat() + EndPriority.tofloat());
			break;
		case ModelType.DISTANCE_MANHATTAN :
			return AIMap.DistanceManhattan(StartTile, EndTile) / (StartPriority.tofloat() + EndPriority.tofloat());
			break;
		case ModelType.DISTANCE_SHIP :
			return _MinchinWeb_Marine_.DistanceShip(StartTile, EndTile) / (StartPriority.tofloat() + EndPriority.tofloat());
			break;
		case ModelType.DISTANCE_AIR :
			return AIMap.DistanceSquare(StartTile, EndTile) / (StartPriority.tofloat() + EndPriority.tofloat());
			break;
		case ModelType.DISTANCE_NONE :
			return (1.0 / (StartPriority.tofloat() + EndPriority.tofloat()));
			break;
		case ModelType.ONE_OVER_T_SQUARED :
			return ((AIMap.DistanceManhattan(StartTile, EndTile) * AIMap.DistanceManhattan(StartTile, EndTile)) / (StartPriority.tofloat() + EndPriority.tofloat()));
			break;
		default:
			return "ERROR: Bad ModelType. Was supplied: " + Model;
			break;
	}
}

function _MinchinWeb_Atlas_::SetMaxDistance(distance = -1)
{
//	Sets the maximum distance between sources and attractions to be included in the model
//		Negative values remove the limit
	if (distance < 0) {
		this._maxdistance = -1;
	} else {
		this._maxdistance = distance;
	}
}

function _MinchinWeb_Atlas_::SetMaxDistanceModel(newmodel)
{
//	Sets the model type to the provided type
//		Used to calculate the distance between the source and attraction for applying maxdistance

//	DISTANCE_NONE is invalid. Use MinchinWeb.Atlas.SetMaxDistance(-1) instead.
//	ONE_OVER_T_SQUARED is invalid.

	if ((newmodel == ModelType.ONE_D) || (newmodel == ModelType.DISTANCE_MANHATTAN) || (newmodel == ModelType.DISTANCE_SHIP) ||
			(newmodel == ModelType.DISTANCE_AIR)) {
		this._maxdistancemodel = newmodel;
	} else {
		AILog.Warning("MinchinWeb.Atlas.SetMaxDistanceModel() was supplied with an invalide ModelType. Was supplied: " + newmodel ".");
	}
}
