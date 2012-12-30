/*	Dominion Land System Roads v.1 [2012-12-28],
 *		part of Minchinweb's MetaLibrary v.6,
 *	Copyright © 2012 by W. Minchin. For more info,
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
 
//	*Domian Land System* refers to the system of survey in Western Canada. Land
//	was surveyed into 1/2 mile x 1/2 mile "quarter sections" that would be sold
//	to settlers. Roads were placed on a 1 mile x 2 mile grid along the edges of
//	these quarter sections.
//
//	Here, we follow the same idea, although on a square grid. The default grid
//	is 8x8 tiles. This is designed to run as a wrapper on the main road
//	pathfinder.

//	Requires *Pathfinder.Road.nut*

class _MinchinWeb_DLS_ {
	_gridx = null;		///< Grid spacing in x direction
	_gridy = null;		///< Grid spacing in y direction
	_datum = null;		///< This is the 'center' of our survey system
	_basedatum = null;	///< this is the 'grid point' closest to 0,0
	_pathfinder = null;
	_starttile = null;
	_endtile = null;
	_path = null;		///< used to store that path as a array of tile pairs
	_running = null;
	_road_type = null;
	
	constructor() {
		this._gridx = 8;
		this._gridy = 8;
		this._datum = 0;
		this._pathfinder = _MinchinWeb_RoadPathfinder_();
		this._road_type = AIRoad.ROADTYPE_ROAD;
	}
}

class _MinchinWeb_DLS_.Info
{
	_main = null;
	
	function GetVersion()       { return 1; }
//	function GetMinorVersion()	{ return 0; }
	function GetRevision()		{ return 0; }
	function GetDate()          { return "2012-12-28"; }
	function GetName()          { return "Dominion Land System Road"; }
	
	constructor(main)
	{
		this._main = main;
	}
}


function _MinchinWeb_DLS_::SetDatum(NewDatum) {
//	## SetDatum
//	Used to set the datum for our road system  
//	*NewDatum* is assumed to be a TileIndex
//
//	To-DO: Add error check

	this._datum = NewDatum;
//	_MinchinWeb_Log_.Note("Base Datum: x " + AIMap.GetTileX(this._datum) + "%" + this._gridx + "=" + AIMap.GetTileX(this._datum)%this._gridx + ", y:" + AIMap.GetTileY(this._datum) + "%" + this._gridy + "=" + AIMap.GetTileX(this._datum)%this._gridy, 6);
	this._basedatum = AIMap.GetTileIndex(AIMap.GetTileX(this._datum)%this._gridx, AIMap.GetTileY(this._datum)%this._gridy);

	_MinchinWeb_Log_.Note("Datum set to " + AIMap.GetTileX(this._datum) + ", " + AIMap.GetTileY(this._datum) + "; BaseDatum set to " + AIMap.GetTileX(this._basedatum) + ", " + AIMap.GetTileY(this._basedatum), 5);
}

function _MinchinWeb_DLS_::GetDatum() {
//	returns the currently set Datum
	return this._datum;
}

function _MinchinWeb_DLS_::IsGridPoint(Point) {
	//	Returns 'true' iff Point is a grid point
	if (((AIMap.GetTileX(Point) - AIMap.GetTileX(this._datum)) % this._gridx == 0) && ((AIMap.GetTileY(Point) - AIMap.GetTileY(this._datum)) % this._gridy == 0)) {
		return true;
	} else {
		return false;
	}
}

function _MinchinWeb_DLS_::GridPoints(End1, End2) {
//	## GridPoints
//	Returns an array of TileIndexs that are 'grid points' or where roads will
//	have intersections.  
//	*End1* and *End2* are expected to be TileIndex'es
//	End1 and End2 will not be included in the return array

	local x1 = AIMap.GetTileX(End1);
	local y1 = AIMap.GetTileY(End1);
	local x2 = AIMap.GetTileX(End2);
	local y2 = AIMap.GetTileY(End2);

	if (x1 > x2) {
		local tempx = x1;
		x1 = x2;
		x2 = tempx;
	}
	if (y1 > y2) {
		local tempy = y1;
		y1 = y2;
		y2 = tempy;
	}

	_MinchinWeb_Log_.Note("Generating grid points from " + x1 + ", " + y1 + " to " + x2 + ", " + y2, 6);

	//	move to first grid x
	local workingx = x1;
	while ((workingx - AIMap.GetTileX(this._datum)) % this._gridx != 0) {
		workingx++;
	}
	//	move to first grid y
	local workingy = y1;
	while ((workingy - AIMap.GetTileY(this._datum)) % this._gridy != 0) {
		workingy++;
	}

	//	Cycle through all the grid points and add them to our array  
	//	use *do..while* to ensure we get at least one set of grid point per
	//	direction
	local MyArray = [];
	local starty = workingy;
	do {
		do {
			local Holding = AIMap.GetTileIndex(workingx, workingy);
			if ((Holding != End1) && (Holding != End2)) {
				MyArray.push(Holding);
				_MinchinWeb_Log_.Note("Add grid point at " + workingx + ", " + workingy, 7)
			}
			workingy = workingy + this._gridy;
		} while (workingy < y2);
		workingx = workingx + this._gridx;
		workingy = starty;
	} while (workingx < x2);

	_MinchinWeb_Log_.Note("Generated " + MyArray.len() + " grid points.", 6);
	return MyArray;
}

function _MinchinWeb_DLS_::AllGridPoints() {
//	Returns an array of all the 'grid points' on the map
	return _MinchinWeb_DLS_.GridPoints(AIMap.GetTileIndex(1,1), AIMap.GetTileIndex(AIMap.GetMapSizeX() - 2, AIMap.GetMapSizeY() - 2));
}

function _MinchinWeb_DLS_::FindPath(cycles = 10000) {
//	runs the pathfinder
//	add all grid points between the StartTile and EndTile as intermediate end points
//	if the pathfinder ends on an intermediate point, make that the new start point and run the pathfinder again
	local AllTiles = [];		// we use this to return an array of tiles
	local LastTile = this._starttile;
	cycles = 10000;
	local StartArray = [];
	local EndArray = [];
	AllTiles.push(LastTile);	// this adds our starting square to the array

	local WhileLoopCounter = 0;

	_MinchinWeb_Log_.Note("+ while loop before: LastTile " + _MinchinWeb_Array_.ToStringTiles1D([LastTile]), 7); 
	do {
		_MinchinWeb_Log_.Note("++ while loop start: LastTile " + _MinchinWeb_Array_.ToStringTiles1D([LastTile]), 7); 
		StartArray = [LastTile];
		EndArray = _MinchinWeb_DLS_.GridPoints(LastTile, this._endtile);
		EndArray.push(this._endtile);
		_MinchinWeb_Log_.Note("StartArray: " + _MinchinWeb_Array_.ToStringTiles1D(StartArray), 7);
		_MinchinWeb_Log_.Note("EndArray: " + _MinchinWeb_Array_.ToStringTiles1D(EndArray), 7);

		this._pathfinder = null;	// dump old pathfinder
		this._pathfinder = _MinchinWeb_RoadPathfinder_();
		this._pathfinder.PresetQuickAndDirty();
		this._pathfinder.InitializePath(EndArray, StartArray);
		local Ret = this._pathfinder.FindPath(cycles);
		this._running = (Ret == false) ? true : false;


		_MinchinWeb_Log_.Note("AllTiles (before) : " + _MinchinWeb_Array_.ToStringTiles1D(AllTiles, true), 7);
		local TilestoAdd = this._pathfinder.PathToTiles();
		TilestoAdd.remove(0);	//	remove the first tile so we don't get duplicates
		_MinchinWeb_Log_.Note("Path to Tiles: " + _MinchinWeb_Array_.ToStringTiles1D(TilestoAdd, true), 7);
		AllTiles.extend(TilestoAdd);
		_MinchinWeb_Log_.Note("AllTiles (1D): " + _MinchinWeb_Array_.ToStringTiles1D(AllTiles, true), 6);
		LastTile = AllTiles.top();
		_MinchinWeb_Log_.Note("+++ while loop: " + (LastTile != this._endtile) + " && " + (this._running == true) + " = " + ((LastTile != this._endtile) && (this._running == true)) + "  ; LastTile " + _MinchinWeb_Array_.ToStringTiles1D([LastTile]), 7);
		_MinchinWeb_Log_.Note("LastTile " + _MinchinWeb_Array_.ToStringTiles1D([LastTile]), 5);

		WhileLoopCounter++;
//	} while ((LastTile != this._endtile) && (this._running == true));
	} while (LastTile != this._endtile)

	if (LastTile == this._endtile) {
		this._path = AllTiles;
		return true;
	} else {
		//	I don't think we should ever get here...
		//		I guess it might get here if the pathfinder fails
		return false;
	}
}

function _MinchinWeb_DLS_::InitializePath(StartArray, EndArray) {
//	Assumed only the first tile of the start and end array are the ones we care about
	this._starttile = StartArray[0];
	this._endtile = EndArray[0];
	this._path = null;
}

//	Reimplement Pathfinder Functions
function _MinchinWeb_DLS_::BuildPath()
{
	if (this._running) {
		AILog.Warning("You can't build a path while there's a running pathfinder.");
		return false;
	}
	if (this._path == null) {
		AILog.Warning("You have tried to build a 'null' path.");
		return false;
	}
	
	local TestMode = AIExecMode();	//	We're really doing this!

	AIRoad.SetCurrentRoadType(this._road_type);
	for (local i=0; i < this._path.len() - 2; i++) {
		if (AIMap.DistanceManhattan(this._path[i], this._path[i+1]) == 1) {
		//	MD == 1 == road joining the two tiles
			if (!AIRoad.BuildRoad(this._path[i], this._path[i+1])) {
			//	If we get here, then the road building has failed
			//	Possible that the road already exists
			//	TO-DO:
			//	- fail the road builder if the road cannot be built and
			//		does not already exist
			//	return null;
			}
		} else {
		//	Implies that we're building either a tunnel or a bridge
			if (!AIBridge.IsBridgeTile(this._path[i]) && !AITunnel.IsTunnelTile(this._path[i])) {
				if (AIRoad.IsRoadTile(this._path[i])) {
				//	Original example demolishes tile if it's already a road
				//		tile to get around expanded roadbits.
				//	I don't like this approach as it could destroy Railway
				//		tracks/tram tracks/station
				//	TO-DO:
				//	- figure out a way to do this while keeping the other
				//		things I've built on the tile
				//	(can I just remove the road?)
					AITile.DemolishTile(this._path[i]);
				}
				if (AITunnel.GetOtherTunnelEnd(this._path[i]) == this._path[i+1]) {
				//	The assumption here is that the land hasn't changed
				//		from when the pathfinder was run and when we try to
				//		build the path. If the tunnel building fails, we
				//		get the 'can't build tunnel' message, but if the
				//		land has changed such that the tunnel end is at a
				//		different spot than is was when the pathfinder ran,
				//		we skip tunnel building and try and build a bridge
				//		instead, which will fail because the slopes are wrong...
					if (!AITunnel.BuildTunnel(AIVehicle.VT_ROAD, this._path[i])) {
					//	At this point, an error has occured while building the tunnel.
					//	Fail the pathfiner
					//	return null;
						AILog.Warning("MinchinWeb.DLS.BuildPath can't build a tunnel from " + AIMap.GetTileX(this._path[i]) + "," + AIMap.GetTileY(this._path[i]) + " to " + AIMap.GetTileX(this._path[i+1]) + "," + AIMap.GetTileY(this._path[i+1]) + "!!" );
					}
				} else {
				//	if not a tunnel, we assume we're buildng a bridge
					local BridgeList = AIBridgeList_Length(AIMap.DistanceManhattan(this._path[i], this._path[i+1] + 1));
					BridgeList.Valuate(AIBridge.GetMaxSpeed);
					BridgeList.Sort(AIList.SORT_BY_VALUE, false);
					if (!AIBridge.BuildBridge(AIVehicle.VT_ROAD, BridgeList.Begin(), this._path[i], this._path[i+1])) {
					//	At this point, an error has occured while building the bridge.
					//	Fail the pathfiner
					//	return null;
					AILog.Warning("MinchinWeb.DLS.BuildPath can't build a bridge from " + AIMap.GetTileX(this._path[i]) + "," + AIMap.GetTileY(this._path[i]) + " to " + AIMap.GetTileX(this._path[i+1]) + "," + AIMap.GetTileY(this._path[i+1]) + "!! (or the tunnel end moved...)" );
					}
				}
			}
		}
	}
	
	//	End build sequence
	return true;
}

function _MinchinWeb_DLS_::InitializePathOnTowns(StartTown, EndTown)
{
//	Initializes the pathfinder using two towns
//	Assumes that the town centers are road tiles (if this is not the case, the
//		pathfinder will still run, but it will take a long time and eventually
//		fail to return a path)
	return this.InitializePath([AITown.GetLocation(StartTown)], [AITown.GetLocation(EndTown)]);
}

function _MinchinWeb_DLS_::GetPath()
{
//	Returns the path stored by the pathfinder
	if (this._running) {
		AILog.Warning("You can't get the path while there's a running pathfinder.");
		return false;
	}
	return this._path;
}

function _MinchinWeb_DLS_::GetPathLength()
{
//	Runs over the path to determine its length
	if (this._running) {
		AILog.Warning("You can't get the path length while there's a running pathfinder.");
		return false;
	}
	if (this._path == null) {
		AILog.Warning("You have tried to get the length of a 'null' path.");
		return false;
	}
	
	local Length = 0;
	for (local i=0; i < this._path.len() - 2; i++) {
		Length = Length + AIMap.DistanceManhattan(this._path[i], this._path[i+1]);
	}

	return Length;
}

function _MinchinWeb_DLS_::PathToTilePairs()
{
//	Returns a 2D array that has each pair of tiles that path joins
	if (this._running) {
		AILog.Warning("You can't convert a path while there's a running pathfinder.");
		return false;
	}
	if (this._path == null) {
		AILog.Warning("You have tried to convert a 'null' path.");
		return false;
	}
	
	local TilePairs = [];

	for (local i=0; i < this._path.len() - 2; i++) {
		TilePairs.push([this._path[i], this._path[i+1]]);
	}
	
	//	End build sequence
	return TilePairs;
}

function _MinchinWeb_DLS_::PathToTiles() {
	//	Returns a 1D array of the tiles in the path
	return this._path;
}

function _MinchinWeb_DLS_::TilePairsToBuild()
{
//	Similiar to PathToTilePairs(), but only returns those pairs where there
//		isn't a current road connection

	if (this._running) {
		AILog.Warning("You can't convert a (partial) path while there's a running pathfinder.");
		return false;
	}
	if (this._path == null) {
		AILog.Warning("You have tried to convert a (partial) 'null' path.");
		return false;
	}
	
	local TilePairs = [];

	for (local i=0; i < this._path.len() - 2; i++) {
		TilePairs.push([this._path[i], this._path[i+1]]);
	}
	
	//	End build sequence
	return TilePairs;
}

function _MinchinWeb_DLS_::GetBuildCost()
{
//	Turns to 'test mode,' builds the route provided, and returns the cost (all
//		money for AI's is in British Pounds)
//	Note that due to inflation, this value can get stale
//	Returns false if the test build fails somewhere

	if (this._running) {
		AILog.Warning("You can't find the build costs while there's a running pathfinder.");
		return false;
	}
	if (this._path == null) {
		AILog.Warning("You have tried to get the build costs of a 'null' path.");
		return false;
	}
	
	local BeanCounter = AIAccounting();
	local TestMode = AITestMode();
	local Path = this._path;

	AIRoad.SetCurrentRoadType(this._road_type);

	for (local i=0; i < this._path.len() - 2; i++) {
		if (AIMap.DistanceManhattan(this._path[i], this._path[i+1]) == 1) {
		//	MD == 1 == road joining the two tiles
			if (!AIRoad.BuildRoad(this._path[i], this._path[i+1])) {
			//	If we get here, then the road building has failed
			//	Possible that the road already exists
			//	TO-DO
			//	- fail the road builder if the road cannot be built and
			//		does not already exist
			//	return null;
			}
		} else {
		//	Implies that we're building either a tunnel or a bridge
			if (!AIBridge.IsBridgeTile(this._path[i]) && !AITunnel.IsTunnelTile(this._path[i])) {
				if (AIRoad.IsRoadTile(this._path[i])) {
				//	Original example demolishes tile if it's already a road
				//		tile to get around expanded roadbits.
				//	I don't like this approach as it could destroy Railway
				//		tracks/tram tracks/station
				//	TO-DO
				//	- figure out a way to do this while keeping the other
				//		things I've built on the tile
				//	(can I just remove the road?)
					AITile.DemolishTile(this._path[i]);
				}
				if (AITunnel.GetOtherTunnelEnd(this._path[i]) == this._path[i+1]) {
					if (!AITunnel.BuildTunnel(AIVehicle.VT_ROAD, this._path[i])) {
					//	At this point, an error has occured while building the tunnel.
					//	Fail the pathfiner
					//	return null;
					AILog.Warning("MinchinWeb.DLS.GetBuildCost can't build a tunnel from " + AIMap.GetTileX(this._path[i]) + "," + AIMap.GetTileY(this._path[i]) + " to " + AIMap.GetTileX(this._path[i+1]) + "," + AIMap.GetTileY(this._path[i+1]) + "!!" );
					}
				} else {
				//	if not a tunnel, we assume we're buildng a bridge
					local BridgeList = AIBridgeList_Length(AIMap.DistanceManhattan(this._path[i], this._path[i+1] + 1));
					BridgeList.Valuate(AIBridge.GetMaxSpeed);
					BridgeList.Sort(AIList.SORT_BY_VALUE, false);
					if (!AIBridge.BuildBridge(AIVehicle.VT_ROAD, BridgeList.Begin(), this._path[i], this._path[i+1])) {
					//	At this point, an error has occured while building the bridge.
					//	Fail the pathfiner
					//	return null;
					AILog.Warning("MinchinWeb.DLS.GetBuildCost can't build a bridge from " + AIMap.GetTileX(this._path[i]) + "," + AIMap.GetTileY(this._path[i]) + " to " + AIMap.GetTileX(this._path[i+1]) + "," + AIMap.GetTileY(this._path[i+1]) + "!!" );
					}
				}
			}
		}
	}
	
	//	End build sequence
	return BeanCounter.GetCosts();
}

// Pass-thru functions to RoadPathfinder
function _MinchinWeb_DLS_::PresetOriginal() {
	return this._pathfinder.PresetOriginal();
}
function _MinchinWeb_DLS_::PresetPerfectPath() {
	return this._pathfinder.PresetPerfectPath();
}
function _MinchinWeb_DLS_::PresetQuickAndDirty() {
	return this._pathfinder.PresetQuickAndDirty();
}
function _MinchinWeb_DLS_::PresetCheckExisting() {
	return this._pathfinder.PresetCheckExisting()
}
function _MinchinWeb_DLS_::PresetMode6() {
	return this._pathfinder.PresetMode6();
}
function _MinchinWeb_DLS_::PresetStreetcar() {
	return this._pathfinder.PresetStreetcar();
}
