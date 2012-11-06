/*	Atlas v.1-GS r.140 [2011-12-03],
 *		part of Minchinweb's MetaLibrary-GS v.2-GS r.140 [2011-12-03],
 *		adapted from Minchinweb's MetaLibrary v.2 r.134 [2011-06-02].
 *	Copyright © 2011 by W. Minchin. For more info,
 *		please visit http://openttd-noai-wmdot.googlecode.com/
 */
 
/*	The Atlas takes sources (departs) and attractions (destinations) and then
 *		generates a heap of pairs sorted by rating. Ratings can be generated
 *		based on distance alone or can alters by user defined ratings (e.g.
 *		industry productions or town populations).
 */
 
// TO-DO: Add max distance

enum ModelType {
	ONED,
	DISTANCEMANHATTAN,
	DISTANCESHIP,
	DISTANCEAIR,
	DISTANCENONE,
	ONEOVERTSQUARED };
 
class _MinchinWeb_Atlas_ {
	_heap_class = null;
	
	_sources = [];			//	'from' here... (array)
	_attractions = [];		//		'to' here  (array)
	_pairs = null;			//	heap of paired sources and attractions
	
	_ignorepairs = [];		//	a list of pairs to ignore
		
	
	_model = null;			//	enumerated list of possible models
	
	constructor () {
		this._pairs = this._heap_class();
		this._model = DISTANCEMANHATTAN;
		this._ignorepairs = [[-1,-1]];
	}
}

function _MinchinWeb_Atlas_::Reset()
{
//	Resets the Atlas
	this._pairs = this._heap_class();
	this._model = DISTANCEMANHATTAN;
	this._ignorepairs = [[-1,-1]];
	this._sources = [];
	this._attractions = [];
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
	this._attraction.push([Attraction, Priority]);
}

function _MinchinWeb_Atlas_::AddBoth(AddedTile, Priority)
{
//	Adds a tile to the BOTH the sources list and the attractions list with the (same) given priority
	this._sources.push([AddedTile, Priority]);
	this._attraction.push([AddedTile, Priority]);
}

function _MinchinWeb_Atlas_::RunModel()
{
//	Takes the provided sources and destinations and runs the selected traffic model, populating the 'pairs' heap
	for (local i = 0; i < this._sources.len(); i++) {
		for (local j = 0; j < this._attractions.len(); j++) {
			if (Arrays.ContainedIn(this._sources[i][0], this._attractions[j][0], this._ignorelist) == false) {
				this._heap.insert([this._sources[i][0], this._attractions[j][0]], ApplyTrafficModel(this._sources[i] this._attractions[j], this._model));
			}
		}
	}
}

function _MinchinWeb_Atlas_::Pop()
{
//	Returns the top rated pair as an array and removes the pair from the model
	return this._pairs.pop();
}

function _MinchinWeb_Atlas_::Peek()
{
//	Returns the top rated pair (as an array) but DOES NOT remove the pair from the model
	return this._pairs.peek();
}

function _MinchinWeb_Atlas_::SetModel(newmodel)
{
//	Sets the model type to the provided type
//	TO-DO: Provide error check on provided input
	this._model = newmodel;
}

function _MinchinWeb_Atlas_::PrintModel()
{
//	Returns the current model type (as the enum)
	return this._model;
}

function PrintModelType(ToPrint)
{
//	given a ModelType, returns the string equivalent
	
	switch (ToPrint) {
		case ONED :
			return "1-D";
			break;
		case DISTANCEMANHATTAN :
			return "Distance Manhattan";
			break;
		case DISTANCESHIP :
			return "Distance Ship";
			break;
		case DISTANCEAIR :
			return "Distance Air";
			break;
		case DISTANCENONE :
			return "Distance Disregarded";
			break;
		case ONEOVERTSQUARED :
			return "1/t^2";
			break;
		default:
			return "ERROR: Bad ModelType. Supplied " + ToPrint;
			break;
	}
}

function ApplyTrafficModel(StartTile, StartPriority, EndTile, EndPriority, Model)
{
//	Given the start and end points, applies the traffic model and returns the
//		weighting
//	Smaller weightings are considered better

	switch (Model) {
		case ONED :
			return GSTile.Distance1D(StartTile, EndTile) / (StartPriority + EndPriority);
			break;
		case DISTANCEMANHATTAN :
			return GSTile.DistanceManhattan(StartTile, EndTile) / (StartPriority + EndPriority);
			break;
		case DISTANCESHIP :
			return GSTile.DistanceShip(StartTile, EndTile) / (StartPriority + EndPriority);
			break;
		case DISTANCEAIR :
			return GSTile.DistanceCrow(StartTile, EndTile) / (StartPriority + EndPriority);
			break;
		case DISTANCENONE :
			return (1 / (StartPriority + EndPriority));
			break;
		case ONEOVERTSQUARED :
			return ((GSTile.DistanceManhattan(StartTile, EndTile) * GSTile.DistanceManhattan(StartTile, EndTile)) / (StartPriority + EndPriority));
			break;
		default:
			return "ERROR: Bad ModelType. Supplied " + Model;
			break;
	}
}


