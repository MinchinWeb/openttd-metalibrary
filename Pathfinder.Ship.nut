/*	ShipPathfinder v.4, r.240, [2012-06-22],
 *		part of Minchinweb's MetaLibrary v.5,
 *		originally part of WmDOT v.7
 *	Copyright © 2011-12 by W. Minchin. For more info,
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
 
/**	\brief		A Ship Pathfinder.
 *	\version	v.4 (2012-06-22)
 *	\author		W. Minchin (%MinchinWeb)
 *	\since		MetaLibrary v.2
 *
 *	I decided to create a pathfinder based on geometry rather than using the A*
 *	approach I used for roads. My pathfinder works like this:
 *	-	To initialize, a path with two points (the start and end) is added to
 *		the pathfinder. For each following loop:
 *		1.	The shortest (unfinished) path is pulled from the pathfinder.
 *		2.	The path is walked, point-to-point, until land is reached.
 *			-	If land is reached, two lines are drawn at right angles starting
 *				the midpoint (of the land). If water if reached, that point is 
 *				then added to the path, and the path is added to the
 *				'unfinished' list.
 *		3.	If the shortest path is on the 'finished' list (i.e. all water),
 *			then that path is returned. Otherwise, the loop restarts.
 *
 *	With simple geometries, it works fast and well. However, on complex
 *	geometries, it doesn't work as well as I would like. The other problem I
 *	have is that the geometry only works on the basis that the start and end
 *	points are in the same waterbody, and so I created \_MinchinWeb\_WBC\_
 *	(WaterbodyCheck) to confirm this is the case; however it adds running time
 *	to the whole pathfinder. One the plus side, building the path is very
 *	simple: just build buoys at each point along the path!
 *
 *	\requires	Fibonacci Heap v.2
 *	\see		\_MinchinWeb\_WBC\_
 *	\todo		Add image showing how the Ship Pathfinder works
 *	\todo		**Inflection Point Check**: Run the pathfinder without WBC as
 *				long as the length of the paths keep going up. Once the length
 *				starts going down, if the length goes back up, either fail the
 *				pathfinder or invoke WBC.
 */
 
/* 
 *		MinchinWeb.ShipPathfinder.InitializePath(source, goal)
 *									- is provided with a single source and
 *										single goal tile (but both are supplied
 *										as arrays)
 *								 .Info.GetVersion()
 *									  .GetRevision()
 *									  .GetDate()
 *									  .GetName()
 *								 .Cost.[xx]
 *								 .FindPath(iterations)
 *								 .LandHo(TileA, TileB) - move to Marine
 *								 .WaterHo(StartTile, Slope, ThirdQuadrant = false) - move to Marine
 *								 .GetPathLength()
 *								 .CountPathBuoys()
 *								 .BuildPathBuoys()
 *								 .GetPath()
 *								 .OverrideWBC()
 */
 
class _MinchinWeb_ShipPathfinder_
{
	_heap_class = import("queue.fibonacci_heap", "", 2);
	_WBC_class = _MinchinWeb_WBC_;		///< Class used to check if the two points are within the same waterbody
	_max_cost = null;              ///< The maximum cost for a route.
	_cost_tile = null;             ///< The cost for a single tile.
	_cost_turn = null;             ///< The cost that is added to _cost_tile if the direction changes.
	cost = null;                   ///< Used to change the costs.
	
	_max_buoy_spacing = null;	   ///< The maximum spacing between buoys
	
//	_infinity = null;
	_first_run = null;
	_first_run2 = null;
	_waterbody_check = null;
	_points = null;					///< Used to store points considered by the pathfinder. Stored as TileIndexes
	_paths = null;					///< Used to store the paths the pathfinder is working with. Stored as indexes to _points
	_clearedpaths = null;			///< Used to store points pairs that have already been cleared (all water)
	_UnfinishedPaths = null;		///< Used to sort in-progess paths
	_FinishedPaths = null			///< Used to store finished paths
	_testedpaths = null;
	_mypath = null;					///< Used to store the path after it's been found for Building functions
	_running = null;
	info = null;

	constructor()
	{
		this._max_cost = 10000;
		this._cost_tile = 1;
		this._cost_turn = 1;
		this._max_buoy_spacing = 50;
		
//		this._infinity = _MinchinWeb_C_Infinity();
//		this._infinity = 10;	//	For Testing
		this._points = [];
		this._paths = [];
		this._clearedpaths = [];
		this._testedpaths = [];
		this._UnfinishedPaths = this._heap_class();
		this._FinishedPaths = this._heap_class();
		
		this._mypath = null;
		this._running = false;

		this.cost = this.Cost(this);
		this.info = this.Info(this);	
	}
	
	/**	\publicsection
	 *	\brief	Initializes the pathfinder.
	 *	\param	source	Starting tile, as a TileID as the first element of an
	 *					array.
	 *	\param	goal	Ending tile, as a TileID as the first element of an
	 *					array.
	 *	\note	Assumes only one source and goal tile.
	 */
	function InitializePath(source, goal) {
	//	Assumes only one source and goal tile...
		this._points = [];
		this._paths = [];
		this._clearedpaths = [];
		this._UnfinishedPaths = this._heap_class();
		this._FinishedPaths = this._heap_class();
		this._mypath = null;
		this._first_run = true;
		this._first_run2 = true;
		this._running = true;
		
		this._points.push(source[0]);
		this._points.push(goal[0]);
		this._paths.push([0,1]);
		this._UnfinishedPaths.Insert(0, _MinchinWeb_ShipPathfinder_._PathLength(0));
	}
	
	/**	\brief	Runs the pathfinder.
	 *	\param	iterations		Number of cycles to run the pathfinder before
	 *							returning. If set to `-1`, will run until a path
	 *							is found.
	 *	\return	`null` if a path cannot be found.
	 *	\return	the path, if a path is found.
	 *	\return	`False` if the pathfinder is unfinished.
	 */
	function FindPath(iterations);
	
	/**	\brief	Find land!
	 *
	 *	Starting one two water tiles, this function will walk the line between
	 *	them, starting at the outside ends, and return the tiles where it hits
	 *	land.
	 *	\param	TileA	A water tile
	 *	\param	TileB	Another water tile
	 *	\return	A two element, one dimensional array of the tile indexes of the
	 *			first land tiles hit after starting at TileA and TileB.
	 *	\return	`[-1, -1]` if the path is all water (no land).
	 *	\static
	 */
	function LandHo(TileA, TileB);
	
	/**	\brief	To the sea! (Find water)
	 *
	 *	Starts at a given tile and then walks out at the given slope until it
	 *	hits water.
	 *	\param	StartTile	A land tile.
	 *	\param	Slope		The slope of the line to follow out.
	 *	\param	ThirdQuadrant	Whether to follow the slope in the third or
	 *							fourth quadrant.
	 *	\todo	Add image showing the Cartesian quadrants.
	 *
	 *	\return	The first water tile hit.
	 *	\static
	 */
	function WaterHo(StartTile, Slope, ThirdQuadrant = false);
	
	/**	\brief	Runs over the path to determine its length.
	 *	\return	Path length in tiles
	 */
	function GetPathLength();
	
	/**	\brief	Returns the number of potential buoys that may need to be built.
	 */
	function CountPathBuoys();
	
	/**	\brief	Build the buoys along the path.
	 *
	 *	Build the buoys that may need to be built.
	 *	Changes `this._mypath` to be the list of these buoys.
	 */
	function BuildPathBuoys();
	
	/**	\brief	Get the current path.
	 *	\return	The path, as currently held by the pathfinder.
	 */
	function GetPath();
	
	/**	\brief	Skip Waterbody Check
	 *
	 *	This function skips the Waterbody Check at the beginning of the Ship
	 *	Pathfinder run. This is intended for if you have already run Waterbody
	 *	Check or otherwise know that the two points are in the same waterbody.
	 *	\warning	The Ship Pathfinder's behaviour without this check in place
	 *				is not tested, as the Ship Pathfinder assumes the two points
	 *				are in the same waterbody.... Use at your own risk.
	 */
	function OverrideWBC();
};

class _MinchinWeb_ShipPathfinder_.Info {
	_main = null;
	
	function GetVersion()       { return 4; }
//	function GetMinorVersion()	{ return 0; }
	function GetRevision()		{ return 240; }
	function GetDate()          { return "2012-06-23"; }
	function GetName()          { return "Ship Pathfinder (Wm)"; }
	
	constructor(main)
	{
		this._main = main;
	}
};

class _MinchinWeb_ShipPathfinder_.Cost {
	_main = null;

	function _set(idx, val)
	{
		if (this._main._running) throw("You are not allowed to change parameters of a running pathfinder.");

		switch (idx) {
			case "max_cost":          this._main._max_cost = val; break;
			case "tile":              this._main._cost_tile = val; break;
			case "turn":              this._main._cost_turn = val; break;
			case "max_buoy_spacing":  this._main._max_buoy_spacing = val; break;
			default: throw("the index '" + idx + "' does not exist");
		}
		return val;
	}

	function _get(idx)
	{
		switch (idx) {
			case "max_cost":          return this._main._max_cost;
			case "tile":              return this._main._cost_tile;
			case "turn":              return this._main._cost_turn;
			case "max_buoy_spacing":  return this._main._max_buoy_spacing;
			default: throw("the index '" + idx + "' does not exist");
		}
	}

	constructor(main)
	{
		this._main = main;
	}
};

//	== Function definitions ================================================


function _MinchinWeb_ShipPathfinder_::FindPath(iterations)
{
//_MinchinWeb_Log_.Note("A",1);
//	Waterbody Check
	if (this._first_run == true) {
		_MinchinWeb_Log_.Note("Ship Pathfinder running WaterBody Check... (at tick " + AIController.GetTick() + ")", 6);
		local WBC;
		if (this._first_run2 == true) {
			WBC = this._WBC_class();
			WBC.InitializePath([this._points[this._paths[0][0]]], [this._points[this._paths[0][1]]]);
			this._first_run2 = false;
		}
		local SameWaterBody = WBC.FindPath(iterations);
		if ((SameWaterBody == false) || (SameWaterBody == null)) {
			return SameWaterBody;
		} else {
			this._first_run = false;
		}
		if (iterations != -1) { return false; }
	}
	_MinchinWeb_Log_.Note("Starting Ship Pathfinder (at tick " + AIController.GetTick() + ")", 7);
	
	if (iterations == -1) { iterations = _MinchinWeb_C_.Infinity() }	//  = 10000; close enough to infinity but able to avoid infinite loops?
	
//_MinchinWeb_Log_.Note("B",1);	
	for (local j = 0; j < iterations; j++) {
		_MinchinWeb_Log_.Note("UnfinishedPaths count " + this._UnfinishedPaths.Count() + " : " + j + " of " + iterations + " iterations.", 6);
		//	Pop the shortest path from the UnfinishedPath Heap
//_MinchinWeb_Log_.Note("C",1);		
		local WorkingPath = this._UnfinishedPaths.Pop();	//	WorkingPath is the Index to the path in question
		_MinchinWeb_Log_.Note("     UnfinishedPath count after Pop... " + this._UnfinishedPaths.Count(), 7);
		_MinchinWeb_Log_.Note("     Path " + WorkingPath + " popped: " + _MinchinWeb_Array_.ToString1D(this._paths[WorkingPath]) + " l=" + _PathLength(WorkingPath), 6);
		local ReturnWP = false;
//_MinchinWeb_Log_.Note("D",1);
		//	Walk the path segment by segment until we hit land
		for (local i = 0; i < (this._paths[WorkingPath].len() - 1); i++) {
		//	End is around line 306...
		
			_MinchinWeb_Log_.Note("Contained in test... " + i + " : " + (this._paths[WorkingPath].len() - 2) + " : " + _MinchinWeb_Array_.ToString2D(this._clearedpaths) + " " + this._points[this._paths[WorkingPath][i]] + " " + this._points[this._paths[WorkingPath][i+1]] + " : " + _MinchinWeb_Array_.ContainedInPairs(this._clearedpaths, this._points[this._paths[WorkingPath][i]], this._points[this._paths[WorkingPath][i+1]]), 7);

//_MinchinWeb_Log_.Note("E--",1);		
			if (_MinchinWeb_Array_.ContainedInPairs(this._clearedpaths, this._points[this._paths[WorkingPath][i]], this._points[this._paths[WorkingPath][i+1]]) != true) {
//_MinchinWeb_Log_.Note("L",1);
				//	This means we haven't already cleared the path...
				local Land = LandHo(this._points[this._paths[WorkingPath][i]], this._points[this._paths[WorkingPath][i+1]]);
//				_MinchinWeb_Log_.Note("Land : " + _MinchinWeb_Array_.ToString1D(Land) + " : " + _MinchinWeb_Array_.ToStringTiles1D(Land), 7);
				_MinchinWeb_Log_.Note("Land : " + _MinchinWeb_Array_.ToString1D(Land), 7);
				if ((Land[0] == -1) && (Land[1] == -1)) {
//_MinchinWeb_Log_.Note("N",1);
					//	All water
					this._clearedpaths.push([this._points[this._paths[WorkingPath][i]], this._points[this._paths[WorkingPath][i+1]]]);
					ReturnWP = true;
				} else {
//_MinchinWeb_Log_.Note("M",1);
					ReturnWP = false;
					// We're going to test this path and don't want to endlessly
					//		be coming back to it
					this._testedpaths.push(this._paths[WorkingPath]);
					
					//	On hitting land, do the right angle split creating two copies
					//		of the path with a new midpoint
					local m = _MinchinWeb_Extras_.Perpendicular(_MinchinWeb_Extras_.Slope(this._points[this._paths[WorkingPath][i]], this._points[this._paths[WorkingPath][i+1]]));
					local MidPoint = _MinchinWeb_Extras_.MidPoint(Land[0], Land[1]);
					//	Check if Midpoint is on Water. If it is, add it and skip the right angle split
					//	TO-DO: Midpoint should only be added if it's in the same Waterbody as the start and finish...
					if ((AITile.IsWaterTile(MidPoint) == true) && ((Land[0] == -1) || (Land[1] == -1))) {
						local WPPoints = this._paths[WorkingPath];
						local NewPointZIndex = _InsertPoint(MidPoint);
						_MinchinWeb_Log_.Sign(MidPoint, NewPointZIndex + "", 7);
						local WPPointsZ = _MinchinWeb_Array_.InsertValueAt(WPPoints, i+1, NewPointZIndex);
						this._paths[WorkingPath] = WPPointsZ;
						this._UnfinishedPaths.Insert(WorkingPath, _PathLength(WorkingPath));
						_MinchinWeb_Log_.Note("          Midpoint on Water...", 7);
						_MinchinWeb_Log_.Note("     Inserting Path #" + WorkingPath + " : " +  _MinchinWeb_Array_.ToString1D(this._paths[WorkingPath]) + " l=" + _PathLength(WorkingPath), 6);
					} else {
						local NewPoint1 = WaterHo(MidPoint, m, false);
						local NewPoint2 = WaterHo(MidPoint, m, true);
						local WPPoints = this._paths[WorkingPath];
						if (NewPoint1 != null) {
							local NewPoint1Index = _InsertPoint(NewPoint1);
							_MinchinWeb_Log_.Sign(NewPoint1, NewPoint1Index + "", 7);
							local WPPoints1 = _MinchinWeb_Array_.InsertValueAt(WPPoints, i+1, NewPoint1Index);
							
							//	With the new point, check both forward and back to see if the
							//		points both before and after the new midpoint to see if
							//		they can be removed from the path (iff the resulting
							//		segement would be only on the water)
							if ( ((i+3) < WPPoints1.len()) && (LandHo(this._points[WPPoints1[i+1]], this._points[WPPoints1[i+3]])[0] == -1) ) {
								WPPoints1 = _MinchinWeb_Array_.RemoveValueAt(WPPoints1, i+2);
							}
							//	With the new point, check we're not putting the point in
							//		twice in a row...
							if ( ((i+2) < WPPoints1.len()) && (WPPoints1[i+1] == WPPoints1[i+2]) ) {
								WPPoints1 = _MinchinWeb_Array_.RemoveValueAt(WPPoints1, i+1);
								_MinchinWeb_Log_.Note("          Point Removed! " + WPPoints1[i+1] + " i=" + i, 6);
							} else {
								_MinchinWeb_Log_.Note("          Point Kept " + WPPoints1[i+1] + " " + WPPoints1[i+2] +  " i=" + i, 6);
							}
							if ( ((i-1) > 0) && (LandHo(this._points[WPPoints1[i-1]], this._points[WPPoints1[i+1]])[0] == -1)) {
								WPPoints1 = _MinchinWeb_Array_.RemoveValueAt(WPPoints1, i);
								i--;	//	For double point check
							}
							if ( (i > 0) && (WPPoints1[i+1] == WPPoints1[i]) ) {
								WPPoints1 = _MinchinWeb_Array_.RemoveValueAt(WPPoints1, i+1);
								_MinchinWeb_Log_.Note("          Point Removed! " + WPPoints1[i+1] + " i=" + i, 6);
							} else {
								_MinchinWeb_Log_.Note("          Point Kept " + WPPoints1[i] + " " + WPPoints1[i+1] +  " i=" + i, 6);
							}
							//	Put both paths back into the UnfinishedPath heap
							//		(assuming we haven't been down this path before...)
							if (_MinchinWeb_Array_.ContainedIn1DIn2D(this._testedpaths, WPPoints1) != true) {
								this._paths[WorkingPath] = WPPoints1;
								_MinchinWeb_Log_.Note("     Inserting Path #" + WorkingPath + " : " +  _MinchinWeb_Array_.ToString1D(this._paths[WorkingPath]) + " l=" + _PathLength(WorkingPath), 6);
								this._UnfinishedPaths.Insert(WorkingPath, _PathLength(WorkingPath));
							}
						}
						if (NewPoint2 != null) {
							local NewPoint2Index = _InsertPoint(NewPoint2);
							_MinchinWeb_Log_.Sign(NewPoint2, NewPoint2Index + "", 7);
							local WPPoints2 = _MinchinWeb_Array_.InsertValueAt(WPPoints, i+1, NewPoint2Index);
							
							if ( ((i+3) < WPPoints2.len()) && (LandHo(this._points[WPPoints2[i+1]], this._points[WPPoints2[i+3]])[0] == -1) ) {
								WPPoints2 = _MinchinWeb_Array_.RemoveValueAt(WPPoints2, i+2);		
							}
							if ( ((i+2) < WPPoints2.len()) && (WPPoints2[i+1] == WPPoints2[i+2]) ) {
								WPPoints2 = _MinchinWeb_Array_.RemoveValueAt(WPPoints2, i+1);
								_MinchinWeb_Log_.Note("          Point Removed! " + WPPoints2[i+1] + " i=" + i, 6);
							} else {
								_MinchinWeb_Log_.Note("          Point Kept " + WPPoints2[i+1] + " " + WPPoints2[i+2] +  " i=" + i, 6);
							}
							if ( ((i-1) > 0) && (LandHo(this._points[WPPoints2[i-1]], this._points[WPPoints2[i+1]])[0] == -1)) {
								WPPoints2 = _MinchinWeb_Array_.RemoveValueAt(WPPoints2, i);	
								i--;								
							}
							if ( (i > 0) && (WPPoints2[i+1] == WPPoints2[i]) ) {
								WPPoints2 = _MinchinWeb_Array_.RemoveValueAt(WPPoints2, i+1);
								_MinchinWeb_Log_.Note("          Point Removed! " + WPPoints2[i+1] + " i=" + i, 6);
							} else {
								_MinchinWeb_Log_.Note("          Point Kept " + WPPoints2[i] + " " + WPPoints2[i+1] +  " i=" + i, 6);
							}
							//	Put the paths into the UnfinishedPath heap
							//		(assuming we haven't been down this path before...)
							if (_MinchinWeb_Array_.ContainedIn1DIn2D(this._testedpaths, WPPoints2) != true) {
								this._paths.push(WPPoints2);
								_MinchinWeb_Log_.Note("     Inserting Path #" + (this._paths.len() - 1) + " : " +  _MinchinWeb_Array_.ToString1D(WPPoints2) + " l=" + _PathLength(this._paths.len() - 1), 5);
								this._UnfinishedPaths.Insert(this._paths.len() - 1, _PathLength(this._paths.len() - 1));
							}
						}
					}	// End  of if MidPoint is on Water
					i = this._paths[WorkingPath].len();	//	Exits us from the for... loop
				}
//_MinchinWeb_Log_.Note("Q",1);
//				i = this._paths[WorkingPath].len();	//	Exits us from the for... loop
			} else if (i == (this._paths[WorkingPath].len() - 2)){
//_MinchinWeb_Log_.Note("F",1);
			//	If we don't hit land, add the path to the FinishedPaths heap
				_MinchinWeb_Log_.Note("Inserting Finished Path " + WorkingPath + " l=" + _PathLength(WorkingPath), 5);
				this._FinishedPaths.Insert(WorkingPath, _PathLength(WorkingPath));
			}
//_MinchinWeb_Log_.Note("P",1);
		}		// END  for (local i = 0; i < (this._paths[WorkingPath].len() - 1); i++)  i.e. stepping through path

//_MinchinWeb_Log_.Note("G",1);		
		if (ReturnWP == true) {
		//	If everything was water...
			_MinchinWeb_Log_.Note("     Inserting Path #" + WorkingPath + " (all water) on ReturnWP; l=" + _PathLength(WorkingPath), 5);
			this._UnfinishedPaths.Insert(WorkingPath, _PathLength(WorkingPath));
		}

//_MinchinWeb_Log_.Note("H",1);		
		if (this._UnfinishedPaths.Count() == 0) {
//_MinchinWeb_Log_.Note("T",1);
			_MinchinWeb_Log_.Note("Unfinsihed count: " + this._UnfinishedPaths.Count() + " finished: " + this._FinishedPaths.Count(), 6);
			if (this._FinishedPaths.Count() !=0) {
//_MinchinWeb_Log_.Note("U",1);
				this._running = false;
				this._mypath = _PathToTilesArray(this._FinishedPaths.Peek());
				_MinchinWeb_Log_.Note("My Path is " + _MinchinWeb_Array_.ToString1D(this._mypath), 5);
				return this._mypath;
			} else {
//_MinchinWeb_Log_.Note("V",1);
				//	If the UnfinishedPath heap is empty, fail the pathfinder
				this._running = false;
				return null;
			}
		} else {
//_MinchinWeb_Log_.Note("I",1);
			if (this._FinishedPaths.Count() !=0) {
				//	If the Finished heap contains a path that is shorter than any of
				//		the unfinished paths, return the finished path
				
				//	Actaully, if the shortest finished path is within 10% of shortest
				//		unfinished path, call it good enough!!
				local finished = this._PathLength(this._FinishedPaths.Peek());
				local unfinished = this._PathLength(this._UnfinishedPaths.Peek());
//_MinchinWeb_Log_.Note("J--",1);
				if ((finished * 100) < (unfinished * 110)) {
//_MinchinWeb_Log_.Note("K",1);
					this._running = false;
					this._mypath = _PathToTilesArray(this._FinishedPaths.Peek());
					_MinchinWeb_Log_.Note("My Path is " + _MinchinWeb_Array_.ToString1D(this._mypath), 5);
					return this._mypath;
				}
				_MinchinWeb_Log_.Note("          Finished =" + finished + " ; Unfinsihed = " + unfinished, 5);
			}
//_MinchinWeb_Log_.Note("W",1);
		}
		
	}
	return false;
}

function _MinchinWeb_ShipPathfinder_::_PathLength(PathIndex)
{
	local Length = 0.0;
	for (local i = 0; i < (this._paths[PathIndex].len() - 1); i++) {
		Length += _MinchinWeb_Marine_.DistanceShip(this._points[this._paths[PathIndex][i]], this._points[this._paths[PathIndex][i + 1]]);
	}
	return Length;
}

/* static */ function _MinchinWeb_ShipPathfinder_::LandHo(TileA, TileB) {
	_MinchinWeb_Log_.Note("Running LandHo... (" +  _MinchinWeb_Array_.ToStringTiles1D([TileA, TileB]) + ").", 7);
	local LandA = 0;
	local LandB = 0;
	
	local Walker = _MinchinWeb_LW_();
	Walker.Start(TileA);
	Walker.End(TileB);
	local PrevTile = Walker.GetStart();
	local CurTile = Walker.Walk();
	while (!Walker.IsEnd() && (LandA == 0)) {
		if (AIMarine.AreWaterTilesConnected(PrevTile, CurTile) != true) {
			LandA = PrevTile	
		}
		PrevTile = CurTile;
		CurTile = Walker.Walk();
	}
	if (Walker.IsEnd()) {
	//	We're all water!
		return [-1,-1];
	}
	
	Walker.Reset();
	Walker.Start(TileB);
	Walker.End(TileA);
	PrevTile = Walker.GetStart();
	CurTile = Walker.Walk();
	
	while (!Walker.IsEnd() && (LandB == 0)) {
		if (AIMarine.AreWaterTilesConnected(PrevTile, CurTile) != true) {
			LandB = PrevTile	
		}
		PrevTile = CurTile;
		CurTile = Walker.Walk();
	}
	if (Walker.IsEnd()) {
	//	We're all water!
		return [-1,-1];
	}

	return [LandA, LandB];
}

/* static */ function _MinchinWeb_ShipPathfinder_::WaterHo(StartTile, Slope, ThirdQuadrant = false)
{
//	Starts at a given tile and then walks out at the given slope until it hits water
	local Walker = _MinchinWeb_LW_();
	Walker.Start(StartTile);
	Walker.Slope(Slope, ThirdQuadrant);
	_MinchinWeb_Log_.Note("    WaterHo! " + StartTile + " , m=" + Slope  + " 3rdQ " + ThirdQuadrant, 7);
	local PrevTile = Walker.GetStart();
	local CurTile = Walker.Walk();
	while ((AIMarine.AreWaterTilesConnected(PrevTile, CurTile) != true) && (AIMap.DistanceManhattan(PrevTile, CurTile) == 1)) {
		PrevTile = CurTile;
		CurTile = Walker.Walk();
	}
	
	if (AIMarine.AreWaterTilesConnected(PrevTile, CurTile) == true) {
		_MinchinWeb_Log_.Note("     WaterHo returning " + _MinchinWeb_Array_.ToStringTiles1D([CurTile]), 7);
		return CurTile;
	} else {
		return null;
	}
}

function _MinchinWeb_ShipPathfinder_::_PathToTilesArray(PathIndex)
{
//	turns a path into an index to tiles (just the start, end, and turning points)
	local Tiles = [];
	for (local i = 0; i < (this._paths[PathIndex].len()); i++) {
			Tiles.push(this._points[this._paths[PathIndex][i]]);
	} 
	_MinchinWeb_Log_.Note("PathToTilesArray input " + _MinchinWeb_Array_.ToString1D(this._paths[PathIndex]), 7);
	_MinchinWeb_Log_.Note("     and output " + _MinchinWeb_Array_.ToString1D(Tiles), 7);
	return Tiles;
}

function _MinchinWeb_ShipPathfinder_::GetPathLength()
{
//	Runs over the path to determine its length
	if (this._running) {
		AILog.Warning("You can't get the path length while there's a running pathfinder.");
		return false;
	}
	if (this._mypath == null) {
		AILog.Warning("You have tried to get the length of a 'null' path.");
		return false;
	}
	
	local Length = 0;
	for (local i = 0; i < (this._mypath.len() - 1); i++) {
		Length += _MinchinWeb_Marine_.DistanceShip(this._mypath[i], this._mypath[i + 1]);
	}
	
	return Length;
}

function _MinchinWeb_ShipPathfinder_::_InsertPoint(TileIndex)
{
//	Inserts a point into point list. Does a check to insure that the same point
//		does not show up twice at different indexes.
//	Returns the index of the point
	local Index =  _MinchinWeb_Array_.Find1D(this._points, TileIndex);
	if (Index == false) {
		this._points.push(TileIndex);
		return (this._points.len() - 1);
	} else {
		return Index;
	}
}

function _MinchinWeb_ShipPathfinder_::CountPathBuoys()
{
//	returns the number of potential buoys that may need to be built

	_MinchinWeb_Log_.Note("My Path is " + _MinchinWeb_Array_.ToString1D(this._mypath), 7);

	if (this._mypath == null) {
		AILog.Warning("MinchinWeb.ShipPathfinder.CountBuoys() must be supplied with a valid path.");
	} else {
		//	basic direction changes (minus the two ends)
		local Buoys = this._mypath.len() - 2;
		
		//	test for long segments
		for (local i = 1; i < this._mypath.len(); i++) {
			local TestLength = _MinchinWeb_Marine_.DistanceShip(this._mypath[i-1], this._mypath[i]);
			while (TestLength > this._max_buoy_spacing) {
				TestLength -= this._max_buoy_spacing;
				Buoys ++;
			}
		}
		
		return Buoys;
	}
}

function _MinchinWeb_ShipPathfinder_::BuildPathBuoys()
{
//	Build the buoys that may need to be built
//	changes  this._mypath  to be the list of these buoys

	if (this._mypath == null) {
		AILog.Warning("MinchinWeb.ShipPathfinder.BuildBuoys() must be supplied with a valid path.");
	} else {
		for (local i = 0; i < this._mypath.len(); i++) {
			//	skip first and last points
			if ((i != 0) && (i != (this._mypath.len() - 1))) {
				//	Build a bouy at each junction, and update the path if an existing buoy is used
				_MinchinWeb_Log_.Note("Build Buoy " + i + " :" + _MinchinWeb_Array_.ToStringTiles1D([this._mypath[i]]), 5);
				this._mypath[i] = _MinchinWeb_Marine_.BuildBuoy(this._mypath[i]);
			}
		}
		
		// Build extra buoys for long stretches
		for (local i = 1; i < this._mypath.len(); i++) {
			if (_MinchinWeb_Marine_.DistanceShip(this._mypath[i-1], this._mypath[i]) > this._max_buoy_spacing ) {
				local midpoint = _MinchinWeb_Extras_.MidPoint(this._mypath[i-1], this._mypath[i]);
				_MinchinWeb_Marine_.BuildBuoy(midpoint);
				this._mypath = _MinchinWeb_Array_.InsertValueAt(this._mypath, i, midpoint);
				_MinchinWeb_Log_.Note("Build Buoy " + i + " : new dist=" + _MinchinWeb_Marine_.DistanceShip(this._mypath[i-1], this._mypath[i]) + " : at" + _MinchinWeb_Array_.ToStringTiles1D([this._mypath[i]]), 7);
				i--;	//	rescan the section...
			}
		}

		return this._mypath;
	}
}

function _MinchinWeb_ShipPathfinder_::GetPath()
{
//	Returns the path, as currently held by the pathfinder

	if (this._mypath == null) {
		AILog.Warning("MinchinWeb.ShipPathfinder.BuildBuoys() must be supplied with a valid path.");
	} else {
		return this._mypath;
	}
}

function _MinchinWeb_ShipPathfinder_::OverrideWBC()	
{
//	This function skips the Waterbody Check at the beginning of the Ship Pathfinder run
//	This is intended for if you have already run Waterbody Check or otherwise know
//		that the two points are in the same waterbody.
//	Be warned that Ship Pathfinder's behaviour without this check in place is not
//		tested, as the Ship Pathfinder assumes the two points are in the same
//		waterbody...

	this._first_run == false;
	_MinchinWeb_Log_.Note("WaterBody Check has been overridden", 6);
}
// EOF

	