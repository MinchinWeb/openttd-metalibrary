/*	Ship and Marine functions v.1 r.195 [2012-01-06],
 *		part of Minchinweb's MetaLibrary v.2,
 *		originally part of WmDOT v.7
 *	Copyright © 2011-12 by W. Minchin. For more info,
 *		please visit http://openttd-noai-wmdot.googlecode.com/
 */

/* 
 *		MinchinWeb.Ship.DistanceShip(TileA, TileB)
 *							- Assuming open ocean, ship in OpenTTD will travel
 *								45° angle where possible, and then finish up the
 *								trip by going along a cardinal direction
 *					   .GetPossibleDockTiles(IndustryID)
 *							- Given an industry (by IndustryID), searches for
 *								possible tiles to build a dock and retruns the
 *								list as an array of TileIndexs
 *							- Tiles given should be checked to ensure that the
 *								desired cargo is still accepted
 *					   .GetDockFrontTiles(Tile)
 *							- Given a tile, returns an array of possible 'front'
 *								tiles that a ship could access the dock from
 *							- Can be either the land tile of a dock, or the
 *								water tile
 *							- Does not test if there is currently a dock at the
 *								tile
 *							- Might do funny things if the tile given is next to
 *								a river (i.e. a flat tile next to a water tile)
 *					   .BuildBuoy(Tile)
 *							- Attempts to build a buoy, but first checks the box
 *								within MinchinWeb.Constants.BuoyOffset() for an
 *								existing buoy, and makes sure there's nothing
 *								but water between the two. If no existing buoy
 *								is found, one is built.
 *							- Returns the location of the existing or built bouy.
 *							- This will fail if the Tile given is a dock (or
 *								any tile that is not a water tile)
 *						.BuildDepot(DockTile, Front)
 *							- Attempts to build a (water) depot, but first checks 
 *								the box within Constants.WaterDepotOffset() for
 *								an existing depot, and makes sure there's nothing 
 *								but water between the depot and dock. If no 
 *								existing depot is found, one is built.
 *							- Returns the location of the existing or built depot.
 *							- This will fail if the DockTile given is a dock (or 
 *								any tile that is not a water tile)
 *
 *		See also MinchinWeb.ShipPathfinder
 */
 
 
class _MinchinWeb_Marine_ {
	main = null;
}
 
function _MinchinWeb_Marine_::DistanceShip(TileA, TileB)
{
//	Assuming open ocean, ship in OpenTTD will travel 45° angle where possible,
//		and then finish up the trip by going along a cardinal direction
	return ((AIMap.DistanceManhattan(TileA, TileB) - AIMap.DistanceMax(TileA, TileB)) * 0.4 + AIMap.DistanceMax(TileA, TileB)).tointeger();
}

function _MinchinWeb_Marine_::GetPossibleDockTiles(IndustryID)
{
//	Given an industry (by IndustryID), searches for possible tiles to build a
//		dock and returns the list as an array of TileIndexs

//	Tiles given should be checked to ensure that the desired cargo is still
//		accepted

//	Assumes that the industry location retruned is the NE corner of the
//		industry, and that industries fit within a 4x4 block
	local Tiles = [];
	if (AIIndustry.IsValidIndustry(IndustryID) == true) {
		//	Check if the industry already has a dock
		if (AIIndustry.HasDock(IndustryID) == true) {
			return [AIIndustry.GetDockLocation(IndustryID)];
		} else {
		//	If not, build a box and then test all the tiles to see if a dock can
		//		be built there
			local BaseLocation = AIIndustry.GetLocation(IndustryID);
			local StartX = AIMap.GetTileX(BaseLocation) - AIStation.GetCoverageRadius(AIStation.STATION_DOCK);
			local StartY = AIMap.GetTileY(BaseLocation) - AIStation.GetCoverageRadius(AIStation.STATION_DOCK);
			local EndX = AIMap.GetTileX(BaseLocation) + _MinchinWeb_C_.IndustrySize() + AIStation.GetCoverageRadius(AIStation.STATION_DOCK);
			local EndY = AIMap.GetTileY(BaseLocation) + _MinchinWeb_C_.IndustrySize() + AIStation.GetCoverageRadius(AIStation.STATION_DOCK);
			
//			AISign.BuildSign(BaseLocation, "Base");
//			AISign.BuildSign(AIMap.GetTileIndex(StartX,StartY),"Corner Start");
//			AISign.BuildSign(AIMap.GetTileIndex(EndX,EndY),"Corner End");
			
			for (local i = StartX; i < EndX; i++) {
				for (local j = StartY; j < EndY; j++) {
//					AILog.Info("i, j = " + i + ", " + j + " : " + Tiles.len());
					local ex = AITestMode();
					if (AIMarine.BuildDock(AIMap.GetTileIndex(i,j), AIStation.STATION_NEW) == true) {
						Tiles.push(AIMap.GetTileIndex(i,j));
					}
				}
			}		
		}
//		AILog.Info("MinchinWeb.Marine.GetPossibleDockTiles()  " + _MinchinWeb_Array_.ToStringTiles1D(Tiles, true));
		return Tiles;
	} else {
		AILog.Warning("MinchinWeb.Marine.GetPossibleDockTiles() was supplied with an invalid IndustryID. Was supplied " + IndustryID + ".");
		return Tiles;
	}
}

function _MinchinWeb_Marine_::GetDockFrontTiles(Tile)
{
//	Given a tile, returns an array of possible 'front' tiles that a ship could
//		access the dock from
//	Can be either the land tile of a dock, or the water tile
//	Does not test if there is currently a dock at the tile

//	Tiles under Oil Rigs do NOT return  AITile.IsWaterTile(Tile) == true

//	Might do funny things if the tile given is next to a river (i.e. a flat tile
//		next to a water tile)

	local ReturnTiles = [];
	local offset = AIMap.GetTileIndex(0, 0);;
	local DockEnd = null;
	local offsets = [AIMap.GetTileIndex(0, 1), AIMap.GetTileIndex(0, -1),
					 AIMap.GetTileIndex(1, 0), AIMap.GetTileIndex(-1, 0)];
	local next_tile;
	
	if (AIMap.IsValidTile(Tile)) {		
		if (AITile.IsWaterTile(Tile)) {
			// water tile
			DockEnd = Tile;
		} else {
			//	land tile
			switch (AITile.GetSlope(Tile)) {
			//	see  http://vcs.openttd.org/svn/browser/trunk/docs/tileh.png
			//		for slopes
				case 0:
					// flat
					offset = AIMap.GetTileIndex(0, 0);
					break;
				case 3:
					offset = AIMap.GetTileIndex(-1, 0);
					break;	
				case 6:
					offset = AIMap.GetTileIndex(0, -1);
					break;
				case 9:
					offset = AIMap.GetTileIndex(0, 1);
					break;
				case 12:
					offset = AIMap.GetTileIndex(1, 0);
					break;
			}
			
			DockEnd = Tile + offset;
		}
		
		if (DockEnd != null) {
			/* Check all tiles adjacent to the current tile. */
			foreach (offset in offsets) {
				next_tile = DockEnd + offset;
				if (AITile.IsWaterTile(next_tile)) {
					ReturnTiles.push(next_tile);
				}
			}
		}
	} else {
		AILog.Warning("MinchinWeb.Marine.GetDockFrontTiles() was supplied with an invalid TileIndex. Was supplied " + Tile + ".");
	}
	
	return ReturnTiles;
}

function _MinchinWeb_Marine_::BuildBuoy(Tile)
{
//	Attempts to build a buoy, but first checks the box within
//		MinchinWeb.Constants.BuoyOffset() for an existing buoy, and makes sure
//		there's nothing but water between the two. If no existing buoy is found,
//		one is built.

//	Returns the location of the existing or built bouy.

	local StartX = AIMap.GetTileX(Tile) - _MinchinWeb_C_.BuoyOffset();
	local StartY = AIMap.GetTileY(Tile) - _MinchinWeb_C_.BuoyOffset();
	local EndX = AIMap.GetTileX(Tile) + _MinchinWeb_C_.BuoyOffset();
	local EndY = AIMap.GetTileY(Tile) + _MinchinWeb_C_.BuoyOffset();
	
	local Existing = AITileList();
	local UseExistingAt = null;
	
	for (local i = StartX; i < EndX; i++) {
		for (local j = StartY; j < EndY; j++) {
			if (AIMarine.IsBuoyTile(AIMap.GetTileIndex(i,j))) {
				Existing.AddItem(AIMap.GetTileIndex(i,j), AIMap.DistanceManhattan(Tile, AIMap.GetTileIndex(i,j)));
//				AILog.Info("BuildBuoy() : Insert Existing at" + _MinchinWeb_Array_.ToStringTiles1D([AIMap.GetTileIndex(i,j)]));
			}
		}
	}
	
	if (Existing.Count() > 0) {
		Existing.Sort(AIList.SORT_BY_VALUE, AIList.SORT_ASCENDING);
		local TestBuoy = Existing.Begin();
		local KeepTrying = true;
		local WBC = _MinchinWeb_WBC_();
		while (KeepTrying == true) {
			WBC.InitializePath([TestBuoy], [Tile]);
			WBC.PresetSafety(TestBuoy, Tile);
			local WBCResults = WBC.FindPath(-1);
			if (WBCResults != null) {
				UseExistingAt = TestBuoy;
				KeepTrying = false;
			} else {
				if (Existing.IsEnd()) {
					KeepTrying = false;
					UseExistingAt = null;
				} else {
					TestBuoy = Existing.Next();
				}
			}
		}
	}
		
	if (UseExistingAt == null) {
		AIMarine.BuildBuoy(Tile);
		return Tile;	
	} else {
		return UseExistingAt;
	}
}

function _MinchinWeb_Marine_::BuildDepot(DockTile, Front)
{
//	Attempts to build a (water) depot, but first checks the box within
//		MinchinWeb.Constants.WaterDepotOffset() for an existing depot, and makes
//		sure there's nothing but water between the depot and dock. If no
//		existing depot is found, one is built.

//	Returns the location of the existing or built depot.
//	This will fail if the DockTile given is a dock (or any tile that is not a water tile)

	local StartX = AIMap.GetTileX(DockTile) - _MinchinWeb_C_.WaterDepotOffset();
	local StartY = AIMap.GetTileY(DockTile) - _MinchinWeb_C_.WaterDepotOffset();
	local EndX = AIMap.GetTileX(DockTile) + _MinchinWeb_C_.WaterDepotOffset();
	local EndY = AIMap.GetTileY(DockTile) + _MinchinWeb_C_.WaterDepotOffset();
	
	local Existing = AITileList();
	local UseExistingAt = null;
	
	for (local i = StartX; i < EndX; i++) {
		for (local j = StartY; j < EndY; j++) {
			if (AIMarine.IsWaterDepotTile(AIMap.GetTileIndex(i,j))) {
				Existing.AddItem(AIMap.GetTileIndex(i,j), AIMap.DistanceManhattan(DockTile, AIMap.GetTileIndex(i,j)));
//				AILog.Info("BuildDepot() : Insert Existing at" + _MinchinWeb_Array_.ToStringTiles1D([AIMap.GetTileIndex(i,j)]));
			}
		}
	}
	
	if (Existing.Count() > 0) {
		Existing.Sort(AIList.SORT_BY_VALUE, AIList.SORT_ASCENDING);
		local TestDepot = Existing.Begin();
		local KeepTrying = true;
		local WBC = _MinchinWeb_WBC_();
		while (KeepTrying == true) {
			WBC.InitializePath([TestDepot], [DockTile]);
			WBC.PresetSafety(TestDepot, DockTile);
			local WBCResults = WBC.FindPath(-1);
			if (WBCResults != null) {
				UseExistingAt = TestDepot;
				KeepTrying = false;
			} else {
				if (Existing.IsEnd()) {
					KeepTrying = false;
					UseExistingAt = null;
				} else {
					TestDepot = Existing.Next();
				}
			}
		}
	}
		
	if (UseExistingAt == null) {	
		if(AIMarine.BuildWaterDepot(DockTile, Front)) {
		// try and build right at the given spot
			UseExistingAt = DockTile;	
		} else {
		//	if that doesn't work, build it close by
			//	Generate a list of water tiles, and pick one at random
			Existing.Clear();
			for (local i = StartX; i < EndX; i++) {
				for (local j = StartY; j < EndY; j++) {
					if (AITile.IsWaterTile(AIMap.GetTileIndex(i,j))) {
						Existing.AddItem(AIMap.GetTileIndex(i,j), AIBase.Rand());
//						AILog.Info("BuildDepot() : Insert WaterTile at" + _MinchinWeb_Array_.ToStringTiles1D([AIMap.GetTileIndex(i,j)]));
					}
				}
			}
			
			Existing.Sort(AIList.SORT_BY_VALUE, AIList.SORT_ASCENDING);
			local TestDepot = Existing.Begin();
			local KeepTrying = true;
			local WBC = _MinchinWeb_WBC_();
			while (KeepTrying == true) {
				WBC.InitializePath([TestDepot], [DockTile]);
				WBC.PresetSafety(TestDepot, DockTile);
				local WBCResults = WBC.FindPath(-1);
//				AILog.Info("BuildDepot() : WBC on" + _MinchinWeb_Array_.ToStringTiles1D([TestDepot, DockTile]) + " returned " + WBCResults);
				if (WBCResults != null) {
					local Front2 = _MinchinWeb_Extras_.NextCardinalTile(TestDepot, DockTile);
					if (AIMarine.BuildWaterDepot(TestDepot, Front2))
					{
						UseExistingAt = TestDepot;
						KeepTrying = false;
					} else {
						if (Existing.IsEnd()) {
							KeepTrying = false;
							UseExistingAt = null;
						} else {
							TestDepot = Existing.Next();
						}
					}
				} else {
					if (Existing.IsEnd()) {
						KeepTrying = false;
						UseExistingAt = null;
					} else {
						TestDepot = Existing.Next();
					}
				}
			}
		
		}
	}
	
	return UseExistingAt;
}
