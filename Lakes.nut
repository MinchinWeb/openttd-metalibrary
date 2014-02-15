/*	Lakes Check v.2 [2014-02-14],
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
 *	\version	v.2 (2012-02-14)
 *	\author		W. Minchin (%MinchinWeb)
 *	\since		MetaLibrary v.7
 *
 *	Lakes is a replacement for WaterBody Check (\_MinchinWeb\_WBC\_). Lakes
 *		serves to determine if two water tiles are connected by water (i.e. if a
 *		ship could sail between them). It trades memory usage for speed by
 *		caching results. Like WaterBody Check, it will keep trying to find a
 *		connections until there is no possible connection left.
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
		Yes1 [shape=box, label="return\n'true'"];
		Yes2 [shape=box, label="return\n'true'"];
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
 *	\requires	\_MinchinWeb\_DLS\_
 *	\see		\_MinchinWeb\_ShipPathfinder\_
 *	\see		\_MinchinWeb\_WBC\_
 */
 
class _MinchinWeb_Lakes_
{
	_map = null;				///< array that tells which group each tile belongs in (index is [TileX][TileY])
	_connections = null;		///< array that shows the connections to each tile groups (index is [TileGroup])
	_areas = null;				///< array of the defined tile groups (index is [TileGroup])
	_open_neighbours = null;	///< array of tiles that are open from each tile group (index is [TileGroup]) (form is [Edge_Tile, Past_Edge_Tile])
	_AGroup = null;				///< array of groups containing source tiles
	_BGroup = null;				///< array of groups containing goal tiles
	_A = null;					///< array of source tiles
	_B = null;					///< array of goal tiles

	_running = null;
	
	constructor() {
		this._map = _MinchinWeb_Array_.Create2D(AIMap.GetMapSizeX(), AIMap.GetMapSizeY());
		this._connections = [];
		this._areas = [];
		this._open_neighbours = [];
		this._running = false;
		
		_AddGridPoints();
	};

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
	};

	/**
	 * Try to find if the source and goal tiles are within the same waterbody.
	 * \param	iterations	After how many iterations it should abort for a
	 *						moment. This value should either be -1 for infinite,
	 *						or > 0. Any other value aborts immediately and will
	 *						never find a path.
	 * \return	'true' if within the same waterbody, or 'false' if the amount of
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
	
	/**	\public
	 *	\brief	Get the minimum distance between the source and destination
	 *			tiles.
	 *	\note	Distance is calculated as Manhattan Distance
	 */
	function GetPathLength();
};


function _MinchinWeb_Lakes_::FindPath(iterations) {
	//	This is where the meat and potatoes is!
	//	See the diagram in the docs for how this works
	if (iterations < 0) {
		iterations = _MinchinWeb_C_.Infinity();
	}
	for (local i = 0; i < iterations; i++) {
		//	Get not only the groups the tiles are in, but all the tile groups
		//		that are connected
		local AAllGroups = _AllGroups(this._AGroup);
		_MinchinWeb_Log_.Note("AGroup: " + _MinchinWeb_Array_.ToString1D(this._AGroup, false) + " All A:" + _MinchinWeb_Array_.ToString1D(AAllGroups, false), 6);
		
		for (local j = 0; j < AAllGroups.len(); j++) {
			if (_MinchinWeb_Array_.ContainedIn1D(this._BGroup, AAllGroups[j])) {
				//	If we have a connection, return 'true'
				_MinchinWeb_Log_.Note("B Group found in A All Groups!", 6);
				return true;
			}
		}
		
		//	No match (yet anyway...)
		//	Get all the open neighbours of A
		local ANeighbours = [];
		local AEdge = [];
		local BAllGroups = [];
		local BNeighbours = [];
		local BEdge = [];
		AAllGroups = _AllGroups(this._AGroup);
		BAllGroups = _AllGroups(this._BGroup);
		for (local j = 0; j < AAllGroups.len(); j++) {
			ANeighbours = _MinchinWeb_Array_.Append(ANeighbours, this._open_neighbours[AAllGroups[j]]);
			AEdge = _MinchinWeb_Array_.Append(AEdge, this._open_neighbours[AAllGroups[j]][0]);
		}
		for (local j = 0; j < BAllGroups.len(); j++) {
			BNeighbours = _MinchinWeb_Array_.Append(BNeighbours, this._open_neighbours[BAllGroups[j]]);
			BEdge = _MinchinWeb_Array_.Append(BEdge, this._open_neighbours[BAllGroups[j]][0]);
		}
		_MinchinWeb_Log_.Note("A -- Edge: " + AEdge.len() + "  Neighbours: " + ANeighbours.len() + "  //  B -- Edge: " + BEdge.len() + "  Neighbours: " + BNeighbours.len(), 6);
		_MinchinWeb_Log_.Note(this._open_neighbours + "  -- len " + this._open_neighbours.len() + " -- [0] " + this._open_neighbours[0] + " -- [0][0] " + this._open_neighbours[0][0] + " -- [0][0][0] " + this._open_neighbours[0][0][0], 7);
		_MinchinWeb_Log_.Note("Open Neighbours :" , 7);
		
		if (ANeighbours.len() > 0) {
			//	Get the tile from AEdge that is closest to BEdge
			local ATileList = AIList();
			for (local k = 0; k < ANeighbours.len(); k++) {
				ATileList.AddItem(ANeighbours[k][0], 0);
			}
			ATileList.Valuate(_MinchinWeb_Extras_.MinDistance, BEdge);
			ATileList.Sort(AIList.SORT_BY_VALUE, AIList.SORT_DESCENDING);

			//	Process the tile's 4 neighbours
			_AddNeighbour(ATileList.Begin());
		} else {
			//	With no 'open neighbours', there can be no more connections
			this._running = false;
			return null;
		}
		
		AAllGroups = [];
		ANeighbours = [];
		AEdge = [];
		BAllGroups = [];
		BNeighbours = [];
		BEdge = [];
		AAllGroups = _AllGroups(this._AGroup);
		BAllGroups = _AllGroups(this._BGroup);
		for (local j = 0; j < BAllGroups.len(); j++) {
			BNeighbours = _MinchinWeb_Array_.Append(BNeighbours, this._open_neighbours[BAllGroups[j]]);
			BEdge = _MinchinWeb_Array_.Append(BEdge, this._open_neighbours[BAllGroups[j]][0]);
		}
		
		if (BNeighbours.len() > 0) {
			//	Get the tile from AEdge that is closest to BEdge
			local BTileList = AIList();
			for (local k = 0; k < BNeighbours.len(); k++) {
				BTileList.AddItem(BNeighbours[k][0], 0);
			}
			BTileList.Valuate(_MinchinWeb_Extras_.MinDistance, AEdge);
			BTileList.Sort(AIList.SORT_BY_VALUE, AIList.SORT_DESCENDING);

			//	Process the tile's 4 neighbours
			_AddNeighbour(BTileList.Begin());
		} else {
			//	With no 'open neighbours', there can be no more connections
			return null;
		}
	}
	
	//	ran out of loops, we're still running
	return false;
}

function _MinchinWeb_Lakes_::GetPathLength() {
	local BList = _MinchinWeb_Array_.ToAIList(this._B);
	local MinDist = _MinchinWeb_C_.Infinity();
	BList.Valuate(_MinchinWeb_Extras_.MinDistance, this._A);
	return BList.GetValue(BList.Begin()); // value of first item
}

//	== Functions not related to the pathfinder ===============================

function _MinchinWeb_Lakes_::_AddGridPoints() {
	local myDLS = _MinchinWeb_DLS_();
	local Grid = myDLS.AllGridPoints()
	
	foreach (point in Grid) {
		AddPoint(point)
	}
}

function _MinchinWeb_Lakes_::AddPoint(myTileID) {
	local x = AIMap.GetTileX(myTileID)
	local y = AIMap.GetTileY(myTileID)
	local xyArea = this._map[x][y];
	// _MinchinWeb_Log_.Note("Tile Area " + x + " / " + y + " : " + xyArea + " : " + this._map.len() + " / " + this._map[x].len() + " : " + this._areas.len(), 6);
	// _MinchinWeb_Log_.Note( _MinchinWeb_Array_.ToString1D(this._map[x], false, true), 7);
	
	if (xyArea != null) {
		//	already in _map
		if (this._map[x][y] == -1) {
			return false;
		} else {
			return this._map[x][y];
		}
	} else if (AITile.IsWaterTile(myTileID) == true) {
		//	add to _map if a water tile
		local myArea = this._areas.len();
		this._areas.append(myTileID);
		this._open_neighbours.append([]);
		this._connections.append([]);
		this._map[x][y] = myArea;
		
		local offsets = [AIMap.GetTileIndex(0, 1), AIMap.GetTileIndex(0, -1),
					 AIMap.GetTileIndex(1, 0), AIMap.GetTileIndex(-1, 0)];

		foreach (offset in offsets) {
			local next_tile = myTileID + offset;
			if (AIMarine.AreWaterTilesConnected(myTileID, next_tile)) {
				this._open_neighbours[myArea].append([myTileID, next_tile]);
				//_MinchinWeb_Log_.Note("Added Neighbours :" + myArea + " [" + _MinchinWeb_Array_.ToStringTiles1D(this._open_neighbours[myArea][this._open_neighbours[myArea].len() - 1]) + "]", 7);
			}
		/*	else {
				_MinchinWeb_Log_.Note("Skipped Neighbours :" + myArea + " [" + myTileID + ", " + next_tile + "]", 7);
			} */
		}
		
		
		_MinchinWeb_Log_.Sign(myTileID, "L" + myArea, 7);
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

	local loops = 0;
	local StartIndex = 0;
	local ReturnGroup = StartGroupArray;
	local NextStartIndex = 0;
	local MoreAdded = true;
	
	do {
		_MinchinWeb_Log_.Note("In AllGroups(), loop " + loops + ". start: " + StartIndex + " // " + _MinchinWeb_Array_.ToString1D(ReturnGroup, false), 7);
		MoreAdded = false;
		NextStartIndex = ReturnGroup.len();
		for (local i = StartIndex; i < NextStartIndex; i++) {
			if (this._connections[ReturnGroup[i]].len() > 0) {
				ReturnGroup = _MinchinWeb_Array_.Append(ReturnGroup, this._connections[ReturnGroup[i]]);
				ReturnGroup = _MinchinWeb_Array_.RemoveDuplicates(ReturnGroup);
				MoreAdded = true;
			}
		}
		StartIndex = NextStartIndex;
		loops++;
	} while (MoreAdded == true)
	
	return ReturnGroup;
}

function _MinchinWeb_Lakes_::_AddNeighbour(NextTile) {
	//	Start by finding out what area we're expanding
	local FromTiles = [];
	for (local i = 0; i < this._open_neighbours.len(); i++) {
		for (local j = 0; j < this._open_neighbours[i].len(); j++) {
			if (this._open_neighbours[i][j][0] == NextTile) {
				FromTiles.append(this._open_neighbours[i][j][1]);
			}
		}
	}
	
	if (FromTiles.len() == 0) {
		//	if something broke, spit out useful debug information
		_MinchinWeb_Log_.Warning("MinchinWeb.Lakes._AddNeighbour() failed.");
		_MinchinWeb_Log_.Note("    this._open_neighbours");
		for (local i = 0; i < this._open_neighbours.len(); i++) {
			_MinchinWeb_Log_.Note("    [" + i + "] " + _MinchinWeb_Array_.ToString2D(this._open_neighbours[i]), 0);
		}
		_MinchinWeb_Log_.Error("No source for " + _MinchinWeb_Array_.ToStringTiles1D([NextTile]));
	}
	
	local FromGroup = this._map[AIMap.GetTileX(FromTiles[0])][AIMap.GetTileY(FromTiles[0])];
	this._map[AIMap.GetTileX(NextTile)][AIMap.GetTileY(NextTile)] = FromGroup;
	
	//	If more than one groups list this tile as an open neighbour, register
	//	the two groups are now linked
	//_MinchinWeb_  //I'M HERE	//	MORE
	for (local i = 0; i < FromTiles.len(); i++) {
		//	remove open neighbour
		local ActiveFromGroup = this._map[AIMap.GetTileX(FromTiles[i])][AIMap.GetTileY(FromTiles[i])];
		for (local j = 0; j < this._open_neighbours[ActiveFromGroup].len(); j++) {
			if (this._open_neighbours[ActiveFromGroup][j][1] == NextTile) {
				this._open_neighbours[ActiveFromGroup] = _MinchinWeb_Array_.RemoveValueAt(this._open_neighbours[ActiveFromGroup], j);
			}
		}
		
		//	register connections
		this._connections[FromGroup].append(ActiveFromGroup);
		this._connections[ActiveFromGroup].append(FromGroup);
		
		//	remove duplicates
		this._connections[ActiveFromGroup] = _MinchinWeb_Array_.RemoveDuplicates(this._connections[ActiveFromGroup]);
	}
	//	remove more duplicates
	this._connections[FromGroup] = _MinchinWeb_Array_.RemoveDuplicates(this._connections[FromGroup]);
	
	//	now add neighbours to newly added tile
	local offsets = [AIMap.GetTileIndex(0, 1), AIMap.GetTileIndex(0, -1),
				 AIMap.GetTileIndex(1, 0), AIMap.GetTileIndex(-1, 0)];

	//	add the new tiles neighbours to the open neighbours list
	foreach (offset in offsets) {
		local OffsetTile = NextTile + offset;
		if (AIMarine.AreWaterTilesConnected(NextTile, OffsetTile)) {
			this._open_neighbours[FromGroup].append([NextTile, OffsetTile]);
		}
	}
	
	Log.Sign(NextTile, "L" + myArea, 7);
}
//	EOF
