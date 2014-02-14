/*	Lakes Check v.2 [2014-02-08],
 *		part of Minchinweb's MetaLibrary v.7,
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
 *	\author		W. Minchin (%MinchinWeb)
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
 *	\dot
	digraph G {
		Start -> {B; A};
		A -> AreaA;
		B -> AreaB;
		AreaA -> AddPtA [label="unknown"];
		{AreaA; AreaB} -> Match [label="known"];
		AreaB -> AddPtB [label="unknown"];
		Match -> Yes1 [label="yes"];
		Match -> StillEdges [label="no"];
		{AddPtA; AddPtB} -> StillEdges;
		StillEdges -> StillEdgeA [label="yes"];
		StillEdgeA -> StillEdgeB [label="no"];
		StillEdgeB -> StillEdges [label="no"]
		StillEdgeA -> PickEdgeA -> AMatchB;
		AMatchB -> FoundMatch [label="yes"];
		AMatchB -> AddA [label="no"];
		AddA -> AddEdgeA -> StillEdgeB -> PickEdgeB;
		PickEdgeB -> BMatchA;
		BMatchA -> FoundMatch [label="yes"];
		BMatchA -> AddB [label="no"];
		AddB -> AddEdgeB -> StillEdges;
		FoundMatch -> Yes2;
		StillEdges -> No1 [label="no"];
		
		Start [shape=box];
		A [label="Point A"];
		B [label="Point B"];
		AreaA [shape=diamond, label="Area?"];
		AreaB [shape=diamond, label="Area?"];
		AddPtA [label="Add Point"];
		AddPtB [label="Add Point"];
		Match [shape=diamond, label="Areas\nmatch?"];
		Yes1 [shape=box, label="return\n'True'"];
		Yes2 [shape=box, label="return\n'True'"];
		No1 [shape=box, label="return\n'null'"];
		StillEdges [shape=diamond, label="Still\nedges?"];
		StillEdgeA [shape=diamond, label="Edge left\non A?"];
		StillEdgeB [shape=diamond, label="Edge left\non B?"];
		PickEdgeA [label="Pick past-edge\nclosest to B"];
		PickEdgeB [label="Pick past-edge\nclosest to A"];
		AMatchB [shape=diamond, label="In B's\n area?"];
		BMatchA [shape=diamond, label="In A's\n area?"];
		AddA [label="Add tile\nto\nArea A"];
		AddB [label="Add tile\nto\nArea B"];
		AddEdgeA [label="Add new\npast-edges"];
		AddEdgeB [label="Add new\npast-edges"];
		FoundMatch [label="Match\nfound!"];
		
		{ rank=same; A -> B [color=white]; }
		{ rank=same; StillEdgeA; StillEdgeB; }
	}
 *	\enddot
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
	_AGroup = null;				///< array of groups containing source tiles
	_BGroup = null;				///< array of groups containing goal tiles
	_A = null;					///< array of source tiles
	_B = null;					///< array of goal tiles

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
	 * \param	sources	The source tiles. Assumed to be an array.
	 * \param	goals	The target tiles. Assumed to be an array.
	 */
	function InitializePath(sources, goals) {
		this._AGroup = [];
		this._BGroup = [];
		this._A = sources;
		this._B = goals;

		foreach (node in sources) {
			this._AGroup.push(this.AddPoint(node));
		}
		foreach (node in goals) {
			this._BGroup.push(this.AddPoint(node));
		}
		this._AGroup = _MinchinWeb_Array_.RemoveDuplicates(this._AGroup);
		this._BGroup = _MinchinWeb_Array_.RemoveDuplicates(this._BGroup);
		this._running = true;
	}

	/**
	 * Try to find if the source and goal tiles are within the same waterbody.
	 * \param	iterations	After how many iterations it should abort for a
	 *						moment. This value should either be -1 for infinite,
	 *						or > 0. Any other value aborts immediately and will
	 *						never find a path.
	 * \return	'True' if within the same waterbody, or 'False' if the amount of
	 *			iterations was reached, or 'null' if no path was found.
	 *  You can call this function over and over as long as it returns false,
	 *  which is an indication it is not yet done looking for a route.
	 */
	function FindPath(iterations);
	
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

	/** \private
	  *	\brief, given a starting group, return all groups attached to it
	  *	\param	StartGroupArray	assumed to be an array
	  */
	function _AllGroups(StartGroupArray);
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

function _MinchinWeb_Lakes_::FindPath(iterations) {
	//	This is where the meat and potatoes is!
	//	See the diagram in the docs for how this works
	if iterations < 0 {
		iterations = _MinchinWeb_C_.Infinity();
	}
	for (local i = 0; i < iterations; i++) {
		//	Get not only the groups the tiles are in, but all the tile groups
		//		that are connected
		AAllGroups = _MinchinWeb_Lakes_._AllGroups(this._AGroup);
		
		for (local j = 0; j < AAllGroups.len() - 1; j++) {
			if _MinchinWeb_Array_.ContainedIn1D(this._BGroup, AAllGroups[j]) {
				//	If we have a connection, return 'True'
				return true;
			}
		}
		
		//	No match (yet anyway...)
		//	Get all the open neighbours of A
		ANeighbours = [];
		AEdge = [];
		BAllGroups = [];
		BNeighbours = [];
		AEdge = [];
		AAllGroups = _MinchinWeb_Lakes_._AllGroups(this._AGroup);
		BAllGroups = _MinchinWeb_Lakes_._AllGroups(this._BGroup);
		for (local j = 0; j < BAllGroups.len() - 1; j++) {
			BNeighbours = _MinchinWeb_Array_.Append(BNeighbours, this._open_neighbours[BAllGroups[j]])
			BEdge = _MinchinWeb_Array_.Append(BEdge, this._open_neighbours[this.BAllGroups[j]][0]);
		}
		if (ANeighbours.len() > 0) {
			//MORE
			//	Get the tile from AEdge that is closest to BEdge
			//	Process the tile's 4 neighbours
			
		} else {
			//	With no 'open neighbours', there can be no more connections
			return null;
		}
		
		AAllGroups = [];
		ANeighbours = [];
		AEdge = [];
		BAllGroups = [];
		BNeighbours = [];
		AEdge = [];
		AAllGroups = _MinchinWeb_Lakes_._AllGroups(this._AGroup);
		BAllGroups = _MinchinWeb_Lakes_._AllGroups(this._BGroup);
		for (local j = 0; j < BAllGroups.len() - 1; j++) {
			BNeighbours = _MinchinWeb_Array_.Append(BNeighbours, this._open_neighbours[BAllGroups[j]])
			BEdge = _MinchinWeb_Array_.Append(BEdge, this._open_neighbours[this.BAllGroups[j]][0]);
		}
		
		if (BNeighbours.len() > 0) {
			//	MORE
			//	Get the tile from BEdge that is closest to AEdge
			//	Process the tile's 4 neighbours
			
		} else {
			//	With no 'open neighbours', there can be no more connections
			return null;
		}
	}
	
	//	ran out of loops, we're still running
	return false;
}

function _MinchinWeb_WBC_::_Estimate(self, cur_tile, cur_direction, goal_tiles) {
	local min_cost = self._max_cost;
	/** As estimate we multiply the lowest possible cost for a single tile with
	 * with the minimum number of tiles we need to traverse. */
	foreach (tile in goal_tiles) {
		min_cost = min(AIMap.DistanceManhattan(cur_tile, tile) * self._cost_per_tile * self._distance_penalty, min_cost);
	}
	return min_cost;
}

function _MinchinWeb_WBC_::_Neighbours(self, path, cur_node) {
	/**	\todo	rewrite
	 */
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

//	== Functions not related to the pathfinder ===============================

function _MinchinWeb_Lakes_::_AddGridPoints() {
	Grid = _MinchinWeb_DLS_.AllGridPoints()
	
	foreach point in Grid {
		this.AddPoint(point)
	}
}

function _MinchinWeb_Lakes_::AddPoint(myTileID) {
	x = AIMap.GetTileX(myTileID)
	y = AIMap.GetTileY(myTileID)
	
	if this._map[x][y] != null {
		//	already in _map
		if this._map[x][y] == -1 {
			return false;
		} else {
			return this._map[x][y];
		}
	} else if AITile.IsWaterTile(myTileID) == true {
		//	add to _map if a water tile
		myArea = this._areas.length()
		this._area.append(myTileID)
		this._neighbours.append([])
		this._map[x][y] = myArea
		
		local offsets = [AIMap.GetTileIndex(0, 1), AIMap.GetTileIndex(0, -1),
					 AIMap.GetTileIndex(1, 0), AIMap.GetTileIndex(-1, 0)];

		foreach (offset in offsets) {
			local next_tile = myTileID + offset;
			if (AIMarine.AreWaterTilesConnected(myTileID, next_tile)) {
				this._open_neighbours[myArea].append([myTileID, next_tile]);
			}
		}
		
		Log.Sign(myTileID, "L" + myArea, 7);
		return myArea;
	} else {
		this._map[x][y] = -1;
		return false;
	}
}

function _MinchinWeb_Lakes_::_AllGroups(StartGroupArray) {
	//	this function starts with an array of starting groups
	//	starts at the beginning and for the first group, appends all connected
	//		groups to the end of the array
	//	does the same for the second and so on until the original end of the
	//		array
	//	next it compacts the resulting array by removing duplicates
	//	then it picks up where it left off in the (now larger) array and starts
	//		adding connections again
	//	this cycle keeps going until no more connections are added that aren't
	//		duplicates

	loops = 0;
	StartIndex = 0;
	ReturnGroup = StartGroupArray;
	NextStartIndex = 0;
	
	do {
		MoreAdded = False;
		NextStartIndex = ReturnGroup.len();
		for (i = StartIndex; i < NextStartIndex; i++) {
			ReturnGroup = _MinchinWeb_Array_.Append(ReturnGroup, this._conenctions[this._AGroup[i]]);
			ReturnGroup = _MinchinWeb_Array_.RemoveDuplicates(ReturnGroup);
			MoreAdded = True;
		}
		StartIndex = NextStartIndex;
		loops++;
	} while (MoreAdded == True)
	
	return ReturnGroup;
}
