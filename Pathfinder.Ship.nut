/*	ShipPathfinder v.1-GS r.144 [2011-12-03],
 *		part of MinchinWeb's MetaLibrary v.2-GS, r.140 [2011-12-03],
 *		adapted from Minchinweb's MetaLibrary v1, r132, [2011-04-30], and
 *		originally part of WmDOT v.6
 *	Copyright © 2011 by W. Minchin. For more info,
 *		please visit http://openttd-noai-wmdot.googlecode.com/
 */
 
/**
 * A Ship Pathfinder.
 */
 
//	TO-DO
//		- Inflections Point Check:
//				Run the pathfinder without WBC as long as the length of the
//					paths keep going up. Once the length starts going down, if
//					the length goes back up, either fail the pathfinder or
//					invoke WBC
 
class _MinchinWeb_ShipPathfinder_
{
//	_heap_class = import("queue.fibonacci_heap", "", 2);
	_heap_class = _MinchinWeb_Fibonacci_Heap_Min_;
	_WBC_class = _MinchinWeb_WBC_;		///< Class used to check if the two points are within the same waterbody
	_max_cost = null;              ///< The maximum cost for a route.
	_cost_tile = null;             ///< The cost for a single tile.
	_cost_turn = null;             ///< The cost that is added to _cost_tile if the direction changes.
	cost = null;                   ///< Used to change the costs.
	
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
	
	function FindPath(iterations);
}

class _MinchinWeb_ShipPathfinder_.Info
{
	_main = null;
	
	function GetVersion()       { return 1; }
	function GetMinorVersion()	{ return 0; }
	function GetRevision()		{ return 144; }
	function GetDate()          { return "2011-12-03"; }
	function GetName()          { return "Ship Pathfinder (MinchinWeb)"; }
	
	constructor(main)
	{
		this._main = main;
	}
}

class _MinchinWeb_ShipPathfinder_.Cost
{
	_main = null;

	function _set(idx, val)
	{
		if (this._main._running) throw("You are not allowed to change parameters of a running pathfinder.");

		switch (idx) {
			case "max_cost":          this._main._max_cost = val; break;
			case "tile":              this._main._cost_tile = val; break;
			case "turn":              this._main._cost_turn = val; break;
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
			default: throw("the index '" + idx + "' does not exist");
		}
	}

	constructor(main)
	{
		this._main = main;
	}
};

function _MinchinWeb_ShipPathfinder_::FindPath(iterations)
{
//	Waterbody Check
	if (this._first_run == true) {
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
	
	if (iterations == -1) {iterations = _MinchinWeb_C_.Infinity() }	//  = 10000; close enough to infinity but able to avoid infinite loops?
	for (local j = 0; j < iterations; j++) {
		GSLog.Info("UnfinishedPaths count " + this._UnfinishedPaths.Count() + " : " + j + " of " + iterations + " iterations.");
		//	Pop the shortest path from the UnfinishedPath Heap
		local WorkingPath = this._UnfinishedPaths.Pop();	//	WorkingPath is the Index to the path in question
//		GSLog.Info("     UnfinishedPath count after Pop... " + this._UnfinishedPaths.Count());
		GSLog.Info("     Path " + WorkingPath + " popped: " + _MinchinWeb_Array_.ToString1D(this._paths[WorkingPath]) + " l=" + _PathLength(WorkingPath));
		local ReturnWP = false;
		//	Walk the path segment by segment until we hit land
		for (local i = 0; i < (this._paths[WorkingPath].len() - 1); i++) {
//			GSLog.Info("Contained in test... " + i + " : " + (this._paths[WorkingPath].len() - 2) + " : " + _MinchinWeb_Array_.ToString2D(this._clearedpaths) + " " + this._points[this._paths[WorkingPath][i]] + " " + this._points[this._paths[WorkingPath][i+1]] + " : " + _MinchinWeb_Array_.ContainedInPairs(this._clearedpaths, this._points[this._paths[WorkingPath][i]], this._points[this._paths[WorkingPath][i+1]]));
		
			if (_MinchinWeb_Array_.ContainedInPairs(this._clearedpaths, this._points[this._paths[WorkingPath][i]], this._points[this._paths[WorkingPath][i+1]]) != true) {
				//	This means we haven't already cleared the path...
				local Land = LandHo(this._points[this._paths[WorkingPath][i]], this._points[this._paths[WorkingPath][i+1]]);
				GSLog.Info("Land : " + _MinchinWeb_Array_.ToString1D(Land) + " : "+ _MinchinWeb_Array_.ToStringTiles1D(Land));
				if ((Land[0] == -1) && (Land[1] == -1)) {
					//	All water
					this._clearedpaths.push([this._points[this._paths[WorkingPath][i]], this._points[this._paths[WorkingPath][i+1]]]);
					ReturnWP = true;
				} else {
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
					if ((GSTile.IsWaterTile(MidPoint) == true) && ((Land[0] == -1) || (Land[1] == -1))) {
						local WPPoints = this._paths[WorkingPath];
						local NewPointZIndex = _InsertPoint(MidPoint);
						GSSign.BuildSign(MidPoint, NewPointZIndex + "");
						local WPPointsZ = _MinchinWeb_Array_.InsertValueAt(WPPoints, i+1, NewPointZIndex);
						this._paths[WorkingPath] = WPPointsZ;
						this._UnfinishedPaths.Insert(WorkingPath, _PathLength(WorkingPath));
						GSLog.Info("          Midpoint on Water...");
						GSLog.Info("     Inserting Path #" + WorkingPath + " : " +  _MinchinWeb_Array_.ToString1D(this._paths[WorkingPath]) + " l=" + _PathLength(WorkingPath));
					} else {
						local NewPoint1 = WaterHo(MidPoint, m, false);
						local NewPoint2 = WaterHo(MidPoint, m, true);
						local WPPoints = this._paths[WorkingPath];
						if (NewPoint1 != null) {
							local NewPoint1Index = _InsertPoint(NewPoint1);
							GSSign.BuildSign(NewPoint1, NewPoint1Index + "");
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
								GSLog.Info("          Point Removed! " + WPPoints1[i+1] + " i=" + i);
							} else {
								GSLog.Info("          Point Kept " + WPPoints1[i+1] + " " + WPPoints1[i+2] +  " i=" + i);
							}
							if ( ((i-1) > 0) && (LandHo(this._points[WPPoints1[i-1]], this._points[WPPoints1[i+1]])[0] == -1)) {
								WPPoints1 = _MinchinWeb_Array_.RemoveValueAt(WPPoints1, i);
								i--;	//	For double point check
							}
							if ( (i > 0) && (WPPoints1[i+1] == WPPoints1[i]) ) {
								WPPoints1 = _MinchinWeb_Array_.RemoveValueAt(WPPoints1, i+1);
								GSLog.Info("          Point Removed! " + WPPoints1[i+1] + " i=" + i);
							} else {
								GSLog.Info("          Point Kept " + WPPoints1[i] + " " + WPPoints1[i+1] +  " i=" + i);
							}
							//	Put both paths back into the UnfinishedPath heap
							//		(assuming we haven't been down this path before...)
							if (_MinchinWeb_Array_.ContainedIn1DIn2D(this._testedpaths, WPPoints1) != true) {
								this._paths[WorkingPath] = WPPoints1;
								GSLog.Info("     Inserting Path #" + WorkingPath + " : " +  _MinchinWeb_Array_.ToString1D(this._paths[WorkingPath]) + " l=" + _PathLength(WorkingPath));
								this._UnfinishedPaths.Insert(WorkingPath, _PathLength(WorkingPath));
							}
						}
						if (NewPoint2 != null) {
							local NewPoint2Index = _InsertPoint(NewPoint2);
							GSSign.BuildSign(NewPoint2, NewPoint2Index + "");
							local WPPoints2 = _MinchinWeb_Array_.InsertValueAt(WPPoints, i+1, NewPoint2Index);
							
							if ( ((i+3) < WPPoints2.len()) && (LandHo(this._points[WPPoints2[i+1]], this._points[WPPoints2[i+3]])[0] == -1) ) {
								WPPoints2 = _MinchinWeb_Array_.RemoveValueAt(WPPoints2, i+2);		
							}
							if ( ((i+2) < WPPoints2.len()) && (WPPoints2[i+1] == WPPoints2[i+2]) ) {
								WPPoints2 = _MinchinWeb_Array_.RemoveValueAt(WPPoints2, i+1);
								GSLog.Info("          Point Removed! " + WPPoints2[i+1] + " i=" + i);
							} else {
								GSLog.Info("          Point Kept " + WPPoints2[i+1] + " " + WPPoints2[i+2] +  " i=" + i);
							}
							if ( ((i-1) > 0) && (LandHo(this._points[WPPoints2[i-1]], this._points[WPPoints2[i+1]])[0] == -1)) {
								WPPoints2 = _MinchinWeb_Array_.RemoveValueAt(WPPoints2, i);	
								i--;								
							}
							if ( (i > 0) && (WPPoints2[i+1] == WPPoints2[i]) ) {
								WPPoints2 = _MinchinWeb_Array_.RemoveValueAt(WPPoints2, i+1);
								GSLog.Info("          Point Removed! " + WPPoints2[i+1] + " i=" + i);
							} else {
								GSLog.Info("          Point Kept " + WPPoints2[i] + " " + WPPoints2[i+1] +  " i=" + i);
							}
							//	Put the paths into the UnfinishedPath heap
							//		(assuming we haven't been down this path before...)
							if (_MinchinWeb_Array_.ContainedIn1DIn2D(this._testedpaths, WPPoints2) != true) {
								this._paths.push(WPPoints2);
								GSLog.Info("     Inserting Path #" + (this._paths.len() - 1) + " : " +  _MinchinWeb_Array_.ToString1D(WPPoints2) + " l=" + _PathLength(this._paths.len() - 1));
								this._UnfinishedPaths.Insert(this._paths.len() - 1, _PathLength(this._paths.len() - 1));
							}
						}
					}	// End  of if MidPoint is on Water
				}
				i = this._paths[WorkingPath].len();	//	Exits us from the for... loop
			} else if (i == (this._paths[WorkingPath].len() - 2)){
			//	If we don't hit land, add the path to the FinishedPaths heap
				GSLog.Info("Inserting Finished Path " + WorkingPath + " l=" + _PathLength(WorkingPath));
				this._FinishedPaths.Insert(WorkingPath, _PathLength(WorkingPath));
			}	
		}		// END  for (local i = 0; i < (this._paths[WorkingPath].len() - 1); i++)
		
		if (ReturnWP == true) {
		//	If everything was water...
			GSLog.Info("     Inserting Path #" + WorkingPath + " (all water) on ReturnWP; l=" + _PathLength(WorkingPath));
			this._UnfinishedPaths.Insert(WorkingPath, _PathLength(WorkingPath));
		}
		
		if (this._UnfinishedPaths.Count() == 0) {
			GSLog.Info("Unfinsihed count: " + this._UnfinishedPaths.Count() + " finished: " + this._FinishedPaths.Count());
			if (this._FinishedPaths.Count() !=0) {
				this._running = false;
				this._mypath = _PathToTilesArray(this._FinishedPaths.Peek());
				GSLog.Info("My Path is " + _MinchinWeb_Array_.ToString1D(this._mypath));
				return this._mypath;
			} else {
				//	If the UnfinishedPath heap is empty, fail the pathfinder
				this._running = false;
				return null;
			}
		} else {
			if (this._FinishedPaths.Count() !=0) {
				//	If the Finished heap contains a path that is shorter than any of
				//		the unfinished paths, return the finished path
				if (this._PathLength(this._FinishedPaths.Peek()) < this._PathLength(this._UnfinishedPaths.Peek()))  {
					this._running = false;
					this._mypath = _PathToTilesArray(this._FinishedPaths.Peek());
					GSLog.Info("My Path is " + _MinchinWeb_Array_.ToString1D(this._mypath));
					return this._mypath;
				}
			}
		}
	}
	return false;
}

function _MinchinWeb_ShipPathfinder_::_PathLength(PathIndex)
{
	local Length = 0.0;
	for (local i = 0; i < (this._paths[PathIndex].len() - 1); i++) {
		Length += _MinchinWeb_Extras_.DistanceShip(this._points[this._paths[PathIndex][i]], this._points[this._paths[PathIndex][i + 1]]);
	}
	return Length;
}

function _MinchinWeb_ShipPathfinder_::LandHo(TileA, TileB) {
	GSLog.Info("Running LandHo... (" +  _MinchinWeb_Array_.ToStringTiles1D([TileA, TileB]) + ").");
	local LandA = 0;
	local LandB = 0;
	
	local Walker = _MinchinWeb_LW_();
	Walker.Start(TileA);
	Walker.End(TileB);
	local PrevTile = Walker.GetStart();
	local CurTile = Walker.Walk();
	while (!Walker.IsEnd() && (LandA == 0)) {
		if (GSMarine.AreWaterTilesConnected(PrevTile, CurTile) != true) {
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
		if (GSMarine.AreWaterTilesConnected(PrevTile, CurTile) != true) {
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

function _MinchinWeb_ShipPathfinder_::WaterHo(StartTile, Slope, ThirdQuadrant = false)
{
//	Starts at a given tile and then walks out at the given slope until it hits water
	local Walker = _MinchinWeb_LW_();
	Walker.Start(StartTile);
	Walker.Slope(Slope, ThirdQuadrant);
	GSLog.Info("    WaterHo! " + StartTile + " , m=" + Slope  + " 3rdQ " + ThirdQuadrant);
	local PrevTile = Walker.GetStart();
	local CurTile = Walker.Walk();
	while ((GSMarine.AreWaterTilesConnected(PrevTile, CurTile) != true) && (GSMap.DistanceManhattan(PrevTile, CurTile) == 1)) {
		PrevTile = CurTile;
		CurTile = Walker.Walk();
	}
	
	if (GSMarine.AreWaterTilesConnected(PrevTile, CurTile) == true) {
		GSLog.Info("     WaterHo returning " + _MinchinWeb_Array_.ToStringTiles1D([CurTile]) );
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
	GSLog.Info("PathToTilesArray input " + _MinchinWeb_Array_.ToString1D(this._paths[PathIndex]) );
	GSLog.Info("     and output " + _MinchinWeb_Array_.ToString1D(Tiles) );
	return Tiles;
}

function _MinchinWeb_ShipPathfinder_::GetPathLength()
{
//	Runs over the path to determine its length
	if (this._running) {
		GSLog.Warning("You can't get the path length while there's a running pathfinder.");
		return false;
	}
	if (this._mypath == null) {
		GSLog.Warning("You have tried to get the length of a 'null' path.");
		return false;
	}
	
	local Length = 0;
	for (local i = 0; i < (this._mypath.len() - 1); i++) {
		Length += _MinchinWeb_Extras_.DistanceShip(this._mypath[i], this._mypath[i + 1]);
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
