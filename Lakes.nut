/*	Lakes Check v.1, r.193, [2012-01-05],
 *		part of Minchinweb's MetaLibrary v.2,
 *		replacement for WaterBody Check
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

/**	\brief		Lakes
 *	\version	v.2 (2012-02-07)
 *	\author		W. Minchin (MinchinWeb)
 *	\since		MetaLibrary v.7
 *
 *	Lakes is a replacement for WaterBody Check (\_MinchinWeb\_WBC\_). Lakes
 *		serves to determine if two water tiles are connected by water (i.e. if a
 *		ship could sail between them). It trades memory usage for speed by
 *		caching results. Like WaterBody Check, it will keep trying to find a
 *		connections until there is no possible connection left.
 *
 *	Pathfinding contained here in is based on the NoAI Team's
 *		Road Pathfinder v3.
 *
 *	\requires	Graph.AyStar v6 library
 *	\requires	\_MinchinWeb\_DLS\_
 *	\see		\_MinchinWeb\_ShipPathfinder\_
 *	\see		\_MinchinWeb\_WBC\_
 */
 
class _MinchinWeb_Lakes_
{
	_map = null;				///< array that tells which group each tile belongs in (index is [TileX][TileY])
	_connections = null;		///< array that shows the connections to each tile groups (index is [TileGroup])
	_areas = null;				///< array of the defined tile groups (index is [TileGroup])
	_open_neighbours = null;	///< array of tiles that are open from each tile group (index is [TileGroup])

	_aystar_class = import("graph.aystar", "", 6);
	_cost_per_tile = null;
	_max_cost = null;              ///< The maximum cost for a route.
	_distance_penalty = null;		///< Penalty to use to speed up pathfinder, 1 is no penalty
	_pathfinder = null;
	cost = null;                   ///< Used to change the costs.
	_running = null;
	_mypath = null;
	
	constructor() {
		this._map = _MinchinWeb_Array_.Create2D(AIMap.GetMapSizeX(), AIMap.GetMapSizeY());
		this._connections = [];
		this._areas = [];
		this._open_neighbours = [];
		
		this._max_cost = 16000;
		this._cost_per_tile = 1;
		this._distance_penalty = 1;
		
		this._pathfinder = this._aystar_class(this, this._Cost, this._Estimate, this._Neighbours, this._CheckDirection);
		this.cost = this.Cost(this);
		this._running = false;
		
		this._AddGridPoints();
	}

	/**	\publicsection
	 * Initialize a path search between sources and goals.
	 * @param sources The source tiles.
	 * @param goals The target tiles.
	 * @see AyStar::InitializePath()
	 */
	function InitializePath(sources, goals) {
		local nsources = [];

		foreach (node in sources) {
			nsources.push([node, 0xFF]);
		}
		this._pathfinder.InitializePath(nsources, goals);
		this._mypath = null;
	}

	/**
	 * Try to find the path as indicated with InitializePath with the lowest cost.
	 * @param iterations After how many iterations it should abort for a moment.
	 *  This value should either be -1 for infinite, or > 0. Any other value
	 *  aborts immediately and will never find a path.
	 * @return A route if one was found, or false if the amount of iterations was
	 *  reached, or null if no path was found.
	 *  You can call this function over and over as long as it returns false,
	 *  which is an indication it is not yet done looking for a route.
	 * @see AyStar::FindPath()
	 */
	function FindPath(iterations);
	
	/**	\brief	How long is the (found) path?
	 *	\return	Path length in tiles
	 */
	function GetPathLength();
	
	/**	\brief	Caps the pathfinder as twice the Manhattan distance between the
	 *			two tiles
	 */
	function PresetSafety(Start, End);
	
	/**	\private
	 *	\brief	Seeds the grid points to Lakes.
	 *
	 *	Called by the class initialization function.
	 */
	function _AddGridPoints();
	
	/**	\public
	 *	\brief	Seeds a point into Lakes.
	 *	\param	myTileID	Assumed to be a tile index.
	 */	
	function AddPoint(myTileID);
};

class _MinchinWeb_WBC_.Cost
{
	/**	\brief	Used to set (and get) pathfinder parameters
	 *
	 *	Valid values are:
	 *	- max_cost
	 *	- cost_per_tile
	 *	- distance_penalty
	 */
	_main = null;

	function _set(idx, val) {
		if (this._main._running) throw("You are not allowed to change parameters of a running pathfinder.");

		switch (idx) {
			case "max_cost":			this._main._max_cost = val; break;
			case "cost_per_tile":		this._main._cost_per_tile = val; break;
			case "distance_penalty":	this._main._distance_penalty = val; break;
			default: throw("the index '" + idx + "' does not exist");
		}

		return val;
	}

	function _get(idx) {
		switch (idx) {
			case "max_cost":			return this._main._max_cost;
			case "cost_per_tile":		return this._main._cost_per_tile;
			case "distance_penalty":	return this._main._distance_penalty;
			default: throw("the index '" + idx + "' does not exist");
		}
	}

	constructor(main) {
		this._main = main;
	}
};

function _MinchinWeb_WBC_::FindPath(iterations) {
	local ret = this._pathfinder.FindPath(iterations);
	this._running = (ret == false) ? true : false;
	if (this._running == false) { this._mypath = ret; }
	return ret;
}


function _MinchinWeb_WBC_::_Cost(self, path, new_tile, new_direction) {
	/* path == null means this is the first node of a path, so the cost is 0. */
	if (path == null) return 0;

//	local prev_tile = path.GetTile();

//	local cost = self._cost_per_tile;
	
//	if (AIMarine.AreWaterTilesConnected(new_tile, prev_tile) != true) {
//		cost = self._max_cost * 10;	//	Basically, way over the top
//	}
//	return path.GetCost() + cost;

	//	this pathfinder will only return tiles adjacent to one another (done in Neighbours...)
	return path.GetCost() + self._cost_per_tile;
}

function _MinchinWeb_WBC_::_Estimate(self, cur_tile, cur_direction, goal_tiles) {
	local min_cost = self._max_cost;
	/* As estimate we multiply the lowest possible cost for a single tile with
	 * with the minimum number of tiles we need to traverse. */
	foreach (tile in goal_tiles) {
		min_cost = min(AIMap.DistanceManhattan(cur_tile, tile) * self._cost_per_tile * self._distance_penalty, min_cost);
	}
	return min_cost;
}

function _MinchinWeb_WBC_::_Neighbours(self, path, cur_node) {
	/* self._max_cost is the maximum path cost, if we go over it, the path isn't valid. */
	if (path.GetCost() >= self._max_cost) return [];
	local tiles = [];

	local offsets = [AIMap.GetTileIndex(0, 1), AIMap.GetTileIndex(0, -1),
					 AIMap.GetTileIndex(1, 0), AIMap.GetTileIndex(-1, 0)];
	/* Check all tiles adjacent to the current tile. */
	foreach (offset in offsets) {
		local next_tile = cur_node + offset;
		if (AIMarine.AreWaterTilesConnected(cur_node, next_tile)) {
			tiles.push([next_tile, self._GetDirection(cur_node, next_tile)]);
		}
	}
	
	/**	\todo	Add diagonals to possible neighbours
	 */
	
	return tiles;
}

function _MinchinWeb_WBC_::_CheckDirection(self, tile, existing_direction, new_direction) {
	return false;
}

function _MinchinWeb_WBC_::_GetDirection(from, to) {
	if (AITile.GetSlope(to) == AITile.SLOPE_FLAT) return 0xFF;
	if (from - to == 1) return 1;
	if (from - to == -1) return 2;
	if (from - to == AIMap.GetMapSizeX()) return 4;
	if (from - to == -AIMap.GetMapSizeX()) return 8;
}

function _MinchinWeb_WBC_::GetPathLength() {
//  Runs over the path to determine its length
    if (this._running) {
        AILog.Warning("You can't get the path length while there's a running pathfinder.");
        return false;
    }
    if (this._mypath == null) {
        AILog.Warning("You have tried to get the length of a 'null' path.");
        return false;
    }
    
    return _mypath.GetLength();
}

function _MinchinWeb_WBC_::PresetSafety(Start, End) {
//	Caps the pathfinder as twice the Manhattan distance between the two tiles
	this._max_cost = this._cost_per_tile * AIMap.DistanceManhattan(Start, End) * 2;
}

//	== Functions not related to the pathfinder ===============================

function _MinchinWeb_WBC_::_AddGridPoints() {
	Grid = _MinchinWeb_DLS_.AllGridPoints()
	
	foreach point in Grid {
		this.AddPoint(point)
	}
}

function _MinchinWeb_WBC_::AddPoint(myTileID) {
	x = AIMap.GetTileX(myTileID)
	y = AIMap.GetTileY(myTileID)
	
	if this._map[x][y] != null {
		//	already in _map
		return this._map[x][y]
	} else if AITile.IsWaterTile(myTileID) == true {
		//	add to _map if a water tile
		this._map[x][y] = this._areas.length()
		
		local offsets = [AIMap.GetTileIndex(0, 1), AIMap.GetTileIndex(0, -1),
					 AIMap.GetTileIndex(1, 0), AIMap.GetTileIndex(-1, 0)];
	
		foreach (offset in offsets) {
			local next_tile = myTileID + offset;
			//// ADD MORE
			if (AIMarine.AreWaterTilesConnected(cur_node, next_tile)) {
				tiles.push([next_tile, self._GetDirection(cur_node, next_tile)]);
			}
		}
		
		this._open_neighbours.append(this.
		this._areas.append(myTileID);
		
	} else {
		return false;
	}
}
