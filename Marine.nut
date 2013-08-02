﻿/*	Ship and Marine functions v.3-GS r.242 [2012-06-23],
 *		part of Minchinweb's MetaLibrary v.5,
 *		originally part of WmDOT v.10
 *	Copyright © 2011-13 by W. Minchin. For more info,
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

/* 
 *		MinchinWeb.Marine.DistanceShip(TileA, TileB)
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
 *						.RateShips(EngineID, Life, Cargo)
 *							- Designed to Run as a validator
 *							- Given the EngineID, it will score them; higher is better
 *							- Life is assumed to be in years
 *							- Note: Cargo doesn't work yet. Capacity is measured in
 *								the default cargo.
 *						.NearestDepot(TileID)
 *							- Returns the tile of the Ship Depot nearest to the
 *								given TileID
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
	return ((GSMap.DistanceManhattan(TileA, TileB) - GSMap.DistanceMax(TileA, TileB)) * 0.4 + GSMap.DistanceMax(TileA, TileB)).tointeger();
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
	if (GSIndustry.IsValidIndustry(IndustryID) == true) {
		//	Check if the industry already has a dock
		if (GSIndustry.HasDock(IndustryID) == true) {
			return [GSIndustry.GetDockLocation(IndustryID)];
		} else {
			local ex = GSTestMode();
			local Walker = _MinchinWeb_SW_();	//	Spiral Walker
			Walker.Start(GSIndustry.GetLocation(IndustryID));
			
			while (Walker.GetStage() <= ((_MinchinWeb_C_.IndustrySize() + GSStation.GetCoverageRadius(GSStation.STATION_DOCK)) * 4)) {
				if (GSMarine.BuildDock(Walker.Walk(), GSStation.STATION_NEW) == true) {
					Tiles.push(Walker.GetTile());
				}
			}
		}
		_MinchinWeb_Log_.Note("MinchinWeb.Marine.GetPossibleDockTiles()  " + _MinchinWeb_Array_.ToStringTiles1D(Tiles, true), 6);
		return Tiles;
	} else {
		GSLog.Warning("MinchinWeb.Marine.GetPossibleDockTiles() was supplied with an invalid IndustryID. Was supplied " + IndustryID + ".");
		return Tiles;
	}
}

function _MinchinWeb_Marine_::GetDockFrontTiles(Tile)
{
//	Given a tile, returns an array of possible 'front' tiles that a ship could
//		access the dock from
//	Can be either the land tile of a dock, or the water tile
//	Does not test if there is currently a dock at the tile

//	Tiles under Oil Rigs do NOT return  GSTile.IsWaterTile(Tile) == true

//	Might do funny things if the tile given is next to a river (i.e. a flat tile
//		next to a water tile)

	local ReturnTiles = [];
	local offset = GSMap.GetTileIndex(0, 0);;
	local DockEnd = null;
	local offsets = [GSMap.GetTileIndex(0, 1), GSMap.GetTileIndex(0, -1),
					 GSMap.GetTileIndex(1, 0), GSMap.GetTileIndex(-1, 0)];
	local next_tile;
	
	if (GSMap.IsValidTile(Tile)) {		
		if (GSTile.IsWaterTile(Tile)) {
			// water tile
			DockEnd = Tile;
		} else {
			//	land tile
			switch (GSTile.GetSlope(Tile)) {
			//	see  http://vcs.openttd.org/svn/browser/trunk/docs/tileh.png
			//		for slopes
				case 0:
					// flat
					offset = GSMap.GetTileIndex(0, 0);
					break;
				case 3:
					offset = GSMap.GetTileIndex(-1, 0);
					break;	
				case 6:
					offset = GSMap.GetTileIndex(0, -1);
					break;
				case 9:
					offset = GSMap.GetTileIndex(0, 1);
					break;
				case 12:
					offset = GSMap.GetTileIndex(1, 0);
					break;
			}
			
			DockEnd = Tile + offset;
		}
		
		if (DockEnd != null) {
			/* Check all tiles adjacent to the current tile. */
			foreach (offset in offsets) {
				next_tile = DockEnd + offset;
				if (GSTile.IsWaterTile(next_tile)) {
					ReturnTiles.push(next_tile);
				}
			}
		}
	} else {
		GSLog.Warning("MinchinWeb.Marine.GetDockFrontTiles() was supplied with an invalid TileIndex. Was supplied " + Tile + ".");
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

	local Existing = GSTileList();
	local UseExistingAt = null;
	
	local Walker = _MinchinWeb_SW_();	//	Spiral Walker
	Walker.Start(Tile);
	
	while (Walker.GetStage() <= (_MinchinWeb_C_.BuoyOffset() * 4)) {
		if (GSMarine.IsBuoyTile(Walker.Walk())) {
			Existing.AddItem(Walker.GetTile(), GSMap.DistanceManhattan(Tile, Walker.GetTile()));
			_MinchinWeb_Log_.Note("BuildBuoy() : Insert Existing at" + _MinchinWeb_Array_.ToStringTiles1D([Walker.GetTile()]), 7);
		}
	}
	
	if (Existing.Count() > 0) {
		Existing.Sort(GSList.SORT_BY_VALUE, GSList.SORT_ASCENDING);
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
		GSMarine.BuildBuoy(Tile);
		return Tile;	
	} else {
		return UseExistingAt;
	}
}

function _MinchinWeb_Marine_::BuildDepot(DockTile, Front, NotNextToDock=true)
{
//	Attempts to build a (water) depot, but first checks the box within
//		MinchinWeb.Constants.WaterDepotOffset() for an existing depot, and makes
//		sure there's nothing but water between the depot and dock. If no
//		existing depot is found, one is built.

//	Returns the location of the existing or built depot.
//	This will fail if the DockTile given is a dock (or any tile that is not a water tile)

//	'NotNextToDock,' when set, will keep the dock from being built next to an
//		exisiting dock

	local StartX = GSMap.GetTileX(DockTile) - _MinchinWeb_C_.WaterDepotOffset();
	local StartY = GSMap.GetTileY(DockTile) - _MinchinWeb_C_.WaterDepotOffset();
	local EndX = GSMap.GetTileX(DockTile) + _MinchinWeb_C_.WaterDepotOffset();
	local EndY = GSMap.GetTileY(DockTile) + _MinchinWeb_C_.WaterDepotOffset();
	
	local Existing = GSTileList();
	local UseExistingAt = null;
	
	for (local i = StartX; i < EndX; i++) {
		for (local j = StartY; j < EndY; j++) {
			if (GSMarine.IsWaterDepotTile(GSMap.GetTileIndex(i,j))) {
				Existing.AddItem(GSMap.GetTileIndex(i,j), GSMap.DistanceManhattan(DockTile, GSMap.GetTileIndex(i,j)));
				_MinchinWeb_Log_.Note("BuildDepot() : Insert Existing at" + _MinchinWeb_Array_.ToStringTiles1D([GSMap.GetTileIndex(i,j)]), 6);
			}
		}
	}
	
	if (Existing.Count() > 0) {
		Existing.Sort(GSList.SORT_BY_VALUE, GSList.SORT_ASCENDING);
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
		if(GSMarine.BuildWaterDepot(DockTile, Front)) {
		// try and build right at the given spot
			UseExistingAt = DockTile;	
		} else {
		//	if that doesn't work, build it close by
			//	Generate a list of water tiles, and pick one at random
			Existing.Clear();
			for (local i = StartX; i < EndX; i++) {
				for (local j = StartY; j < EndY; j++) {
					if (GSTile.IsWaterTile(GSMap.GetTileIndex(i,j)) && (_MinchinWeb_Station_.IsNextToDock(GSMap.GetTileIndex(i,j)) == false) ) {
						Existing.AddItem(GSMap.GetTileIndex(i,j), GSBase.Rand());
						_MinchinWeb_Log_.Note("BuildDepot() : Insert WaterTile at" + _MinchinWeb_Array_.ToStringTiles1D([GSMap.GetTileIndex(i,j)]), 7);
					}
				}
			}
			
			Existing.Sort(GSList.SORT_BY_VALUE, GSList.SORT_ASCENDING);
			local TestDepot = Existing.Begin();
			local KeepTrying = true;
			local WBC = _MinchinWeb_WBC_();
			while (KeepTrying == true) {
				WBC.InitializePath([TestDepot], [DockTile]);
				WBC.PresetSafety(TestDepot, DockTile);
				local WBCResults = WBC.FindPath(-1);
				_MinchinWeb_Log_.Note("BuildDepot() : WBC on" + _MinchinWeb_Array_.ToStringTiles1D([TestDepot, DockTile]) + " returned " + WBCResults, 7);
				if (WBCResults != null) {
					local Front2 = _MinchinWeb_Extras_.NextCardinalTile(TestDepot, DockTile);
					if (GSMarine.BuildWaterDepot(TestDepot, Front2))
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

function _MinchinWeb_Marine_::RateShips(EngineID, Life, Cargo)
{
//	Designed to Run as a validator
//	Given the EngineID, it will score them; higher is better
//	   Score = [(Capacity in Cargo)*Reliability*Speed] / 
//                      [ (Purchase Price over Life) + (Running Costs)*Life ]
//
//	Life is assumed to be in years
//  Note: Cargo doesn't work yet. Capacity is measured in the default cargo.

	local Score = 0;
	local Age = GSEngine.GetMaxAge(EngineID);
	local BuyTimes = (Life / Age/366).tointeger() + 1;;
		// GetMaxAge is given in days
	local Cost = (BuyTimes * GSEngine.GetPrice(EngineID)) + (Life * GSEngine.GetRunningCost(EngineID)) + 0.001;
	local Return = (GSEngine.GetCapacity(EngineID) * GSEngine.GetReliability(EngineID) * GSEngine.GetMaxSpeed(EngineID)) + 0.001;
	if (Return == 0) {
		Score = 0;
	} else {
		Score = (Return * 1000 / Cost).tointeger();
	}
	
	_MinchinWeb_Log_.Note("Rate Ship : " + Score + " : " +GSEngine.GetName(EngineID) + " : " + GSEngine.GetCapacity(EngineID) + " * " + GSEngine.GetReliability(EngineID) + " * " + GSEngine.GetMaxSpeed(EngineID) + " / " + BuyTimes + " * " + GSEngine.GetPrice(EngineID) + " + " + Life + " * " + GSEngine.GetRunningCost(EngineID), 7);
	return Score;
}

function _MinchinWeb_Marine_::NearestDepot(TileID)
{
//	Returns the tile of the Ship Depot nearest to the given TileID

//	To-Do:	Add check that depot is connected to tile
//	To-Do:	Check that there is a depot to return
	local AllDepots = GSDepotList(GSTile.TRANSPORT_WATER);
	AllDepots.Valuate(GSTile.GetDistanceManhattanToTile, TileID);
	AllDepots.Sort(GSList.SORT_BY_VALUE, GSList.SORT_ASCENDING);
	return AllDepots.Begin();
}
