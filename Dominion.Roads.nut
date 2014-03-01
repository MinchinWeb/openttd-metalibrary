/*	Dominion Land System Roads v.1.1 [2013-01-01],
 *		part of Minchinweb's MetaLibrary v.6,
 *	Copyright © 2012-14 by W. Minchin. For more info,
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

/**	\brief		Dominion Land System (Road Pathfinder)
 *	\version	v.1 (2013-01-01)
 *	\author		W. Minchin (%MinchinWeb)
 *	\since		MetaLibrary v.6
 *
 *	*Dominion Land System* refers to the system of survey in Western Canada.
 *	Land was surveyed into 1/2 mile x 1/2 mile "quarter sections" that would be
 *	sold to settlers (around 1905, the price was $10). Roads were placed on a
 *	1 mile x 2 mile grid along the edges of these quarter sections.
 *
 *	Here, we follow the same idea, although on a square grid. The default grid
 *	is 8x8 tiles. This is designed to run as a wrapper on the main road
 *	pathfinder.
 *
 *	\requires	*Pathfinder.Road.nut*
 *	\see		\_MinchinWeb\_RoadPathfinder\_
 */

/*	This file provides the following functions
		MinchinWeb.DLS()
				  .DLS.Info.GetVersion()
				  		   .GetRevision()
				  		   .GetDate()
				  		   .GetName()
				  .DLS.SetDatum()
				  	  .GetDatum()
				  	  .IsGridPoint(Point)
				  	  .GridPoints(End1, End2)
				  	  .AllGridPoints()
				  	  .FindPath(cycles=10000)
				  	  .InitializePath(StartArray, EndArray)
				  	  .BuildPath()
				  	  .InitializePathOnTowns(StartTown, EndTown)
				  	  .GetPath()
				  	  .GetPathLength()
				  	  .PathToTilePairs()
				  	  .PathToTiles()
				  	  .TilePairsToBuild()
				  	  .GetBuildCost()
				  	  .PresetOriginal()
				  	  .PresetPerfectPath()
				  	  .PresetQuickAndDirty()
				  	  .PresetMode6()
				  	  .PresetStreetcar()
*/

class _MinchinWeb_DLS_ {
	_gridx = null;		///< Grid spacing in x direction (default is 8 tiles)
	_gridy = null;		///< Grid spacing in y direction (default is 8 tiles)
	_datum = null;		///< This is the 'centre' of our survey system
	_basedatum = null;	///< this is the 'grid point' closest to 0,0
	_pathfinder = null;	///< the pathfinder itself
	_starttile = null;	///< starting tile
	_endtile = null;	///< ending tile
	_path = null;		///< used to store that path as a array of tile pairs
	_running = null;	///< Is the pathfinder currently running?
	_road_type = null;	///< See <http://noai.openttd.org/api/trunk/classAIRoad.html>
	
	constructor() {
		this._gridx = 8;
		this._gridy = 8;
		this._datum = 0;
		this._pathfinder = _MinchinWeb_RoadPathfinder_();
		this._road_type = AIRoad.ROADTYPE_ROAD;
	}
	
	/**	\publicsection
	 *	\brief	Sets network Datum.
	 *
	 *	Used to set the datum for our road system.
	 *	\note	In surveying, a 'datum' is where all other points are measured
	 *			from.
	 *	\param	NewDatum	assumed to be a TileIndex
	 *	\todo	Add error check
	 */
	function SetDatum(NewDatum);
	
	/**	\brief	Returns the currently set Datum
	 *	\return	The current Datum (as a TileIndex)
	 *	\note	In surveying, a 'datum' is where all other points are measured
	 *			from.
	 */
	function GetDatum() { return this._datum; }
	
	/**	\brief	Is the tile given a grid point
	 *	\return	`True` if and only if `Point` is a gird point;
	 *			`False` otherwise.
	 */
	function IsGridPoint(Point);
	
	/**	\brief	Get all the grid points between two tiles
	 *	\param	End1	expected to be a TileIndex
	 *	\param	End2	expected to be a TileIndex
	 *	\return	An array of TileIndexs that are 'grid points' or where roads
	 *			will have intersections.
	 *	\note	`End1` and `End2` will **NOT** be included in the return array.
	 */
	function GridPoints(End1, End2);
	
	/**	\brief	Get all grid points
	 *	\return	An array of all the 'grid points' on the map
	 */
	function AllGridPoints();
	
	/**	\brief	Run the pathfinder.
	 *	\param	cycles	number of iterations to run before returning.
	 *	\return	`True` when the path is found
	 *	\see	BuildPath()
	 *	\see	GetPath()
	 *	\note	The path must be initialized before it can be run.
	 *	\see	InitializePath()
	 *	\see	InitializePathOnTowns()
	 *	\todo	stop ignoring the passed parameter of `cycles`
	 */
	function FindPath(cycles = 10000);
	
	/**	\brief	Initializes the pathfinder
	 *	\param	StartArray	the first item assumed be a TileIndex, the of the
	 *						items in the array are ignored.
	 *	\param	EndArray	the first item assumed be a TileIndex, the of the
	 *						items in the array are ignored.
	 */
	function InitializePath(StartArray, EndArray);
	
	/**	\brief	Build the path
	 *	\note	requires that the path has already been found.
	 *	\see	FindPath()
	 */
	function BuildPath();

	/**	\brief	Initializes the pathfinder using two towns.
	 *	\param	StartTown	Assumed to be a TownID
	 *	\param	EndTown		Assumed to be a TownID
	 *	\note	This assumes that the town centres are road tiles (if this is
	 *			not the case, the pathfinder will still run, but it will take a
	 *			long time and eventually fail to return a path). This is not
	 *			typically an issue because on map generation, the centre of each
	 *			town is a road tile.
	 */
	function InitializePathOnTowns(StartTown, EndTown);
	
	/** \brief	Returns the path stored by the pathfinder
	 */
	function GetPath();
	
	/**	\brief	Returns the length of the path stored by the pathfinder.
	 *	\return	The lenght of the path in tiles.
	 */
	function GetPathLength();
	
	/**	\brief	Convert the path to tile pairs.
	 *	\return	A 2D array that has each pair of tiles that the path joins.
	 *	\see	TileParisToBuild()
	 */
	function PathToTilePairs();
	
	/**	\brief	Get all the tiles in the path.
	 *	\return	A 1D array of the tiles in the path
	 */
	function PathToTiles() { return this._path; }
	
	/**	\brief	Get the road tile pairs that need built.
	 *
	 *	Similar to PathToTilePairs(), but only returns those pairs where there
	 *	isn't a current road connection.
	 *	\see	PathToTilePairs()
	 *	\return	A 2D array that has each pair of tiles that the path joins that
	 *			are not current joined by road.
	 */
	function TilePairsToBuild();
	
	/**	\brief	Determine how much it will cost to build the path.
	 *
	 *	Turns to 'test mode,' builds the route provided, and returns the cost.
	 *	\return	The build cost, in British Pounds.
	 *	\return	`False` if the test build fails somewhere.
	 *	\note	Note that due to inflation, this value can get stale.
	 */
	function GetBuildCost();
	
	/**	Pass-thru functions to RoadPathfinder
	 *	\see	\_MinchinWeb\_RoadPathfinder\_.PresetOriginal()
	 */
	function PresetOriginal() {
		return this._pathfinder.PresetOriginal();
	}

	/**	Pass-thru functions to RoadPathfinder
	 *	\see	\_MinchinWeb\_RoadPathfinder\_.PresetPerfectPath()
	 */
	function PresetPerfectPath() {
		return this._pathfinder.PresetPerfectPath();
	}
	
	/**	Pass-thru functions to RoadPathfinder
	 *	\see	\_MinchinWeb\_RoadPathfinder\_.PresetQuickAndDirty()
	 */
	function PresetQuickAndDirty() {
		return this._pathfinder.PresetQuickAndDirty();
	}
	
	/**	Pass-thru functions to RoadPathfinder
	 *	\see	\_MinchinWeb\_RoadPathfinder\_.PresetCheckExisting()
	 */
	function PresetCheckExisting() {
		return this._pathfinder.PresetCheckExisting()
	}
	
	/**	Pass-thru functions to RoadPathfinder
	 *	\see	\_MinchinWeb\_RoadPathfinder\_.PresetMode6()
	 */
	function PresetPresetMode6() {
		return this._pathfinder.PresetMode6();
	}
	
	/**	Pass-thru functions to RoadPathfinder
	 *	\see	\_MinchinWeb\_RoadPathfinder\_.PresetStreetcar()
	 */
	function PresetPresetStreetcar() {
		return this._pathfinder.PresetStreetcar();
	}
};

class _MinchinWeb_DLS_.Info {
	_main = null;
	
	function GetVersion()       { return 1; }
//	function GetMinorVersion()	{ return 0; }
	function GetRevision()		{ return 130101; }
	function GetDate()          { return "2013-01-01"; }
	function GetName()          { return "Dominion Land System Roads"; }
	
	constructor(main) {
		this._main = main;
	}
};


function _MinchinWeb_DLS_::SetDatum(NewDatum) {
	this._datum = NewDatum;
//	_MinchinWeb_Log_.Note("Base Datum: x " + AIMap.GetTileX(this._datum) + "%" + this._gridx + "=" + AIMap.GetTileX(this._datum)%this._gridx + ", y:" + AIMap.GetTileY(this._datum) + "%" + this._gridy + "=" + AIMap.GetTileX(this._datum)%this._gridy, 6);
	this._basedatum = AIMap.GetTileIndex(AIMap.GetTileX(this._datum)%this._gridx, AIMap.GetTileY(this._datum)%this._gridy);

	_MinchinWeb_Log_.Note("Datum set to " + AIMap.GetTileX(this._datum) + ", " + AIMap.GetTileY(this._datum) + "; BaseDatum set to " + AIMap.GetTileX(this._basedatum) + ", " + AIMap.GetTileY(this._basedatum), 5);
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
		if ((typeof (TilestoAdd) == "array") && (TilestoAdd.len() > 0)) {
			TilestoAdd.remove(0);	//	remove the first tile so we don't get duplicates
			_MinchinWeb_Log_.Note("Path to Tiles: " + _MinchinWeb_Array_.ToStringTiles1D(TilestoAdd, true), 7);
			AllTiles.extend(TilestoAdd);
		}
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
					//	At this point, an error has occurred while building the tunnel.
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
					//	At this point, an error has occurred while building the bridge.
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
//	Assumes that the town centres are road tiles (if this is not the case, the
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

function _MinchinWeb_DLS_::TilePairsToBuild()
{
//	Similar to PathToTilePairs(), but only returns those pairs where there
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
					//	At this point, an error has occurred while building the tunnel.
					//	Fail the pathfiner
					//	return null;
					AILog.Warning("MinchinWeb.DLS.GetBuildCost can't build a tunnel from " + AIMap.GetTileX(this._path[i]) + "," + AIMap.GetTileY(this._path[i]) + " to " + AIMap.GetTileX(this._path[i+1]) + "," + AIMap.GetTileY(this._path[i+1]) + "!!" );
					}
				} else {
				//	if not a tunnel, we assume we're building a bridge
					local BridgeList = AIBridgeList_Length(AIMap.DistanceManhattan(this._path[i], this._path[i+1] + 1));
					BridgeList.Valuate(AIBridge.GetMaxSpeed);
					BridgeList.Sort(AIList.SORT_BY_VALUE, false);
					if (!AIBridge.BuildBridge(AIVehicle.VT_ROAD, BridgeList.Begin(), this._path[i], this._path[i+1])) {
					//	At this point, an error has occurred while building the bridge.
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
// EOF
