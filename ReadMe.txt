MinchinWeb's MetaLibrary Read-me
v.3, r.210, 2012-01-14
Copyright © 2011-12 by W. Minchin. For more info, please visit
    http://openttd-noai-wmdot.googlecode.com/

-- About MetaLibrary ----------------------------------------------------------
MetaLibrary started as a collection of functions from my AI, WmDOT. The hope is
    to provide a collection of classes and functions that will be useful to
    other AI writers. Your comments, suggestions, and bug reports are welcomed
    and encouraged!

-- Requirements ---------------------------------------------------------------
WmDOT requires OpenTTD version 1.1 or newer. This is available as a free
    download from OpenTTD.org
As dependances, WmDOT also requires:
    - Binary Heap, v.1      ('Queue.BinaryHeap-1.tar')
    - Fibonacci Heap, v.2   ('Queue.FibonacciHeap-2.tar')
    - Graph.AyStar, v.6     ('Graph.AyStar-6.tar')

-- Installation ---------------------------------------------------------------
The easiest (and recommended) way to install MetaLibrary is use OpenTTD's
    'Check Online Content' inferface. Search for 'MetaLibrary.' If you have not
    already installed the required dependancy libraries, OpenTTD will prompt you
    to download them at the same time. This also makes it very easy for me to
    provide updates.
Manual installation can be accomplished by putting the
    'MinchinWebs_MetaLibrary-3.tar' file you downloaded in the
    '..\OpenTTD\ai\library'  folder. If you are manually installing,
    the libraries mentioned above need to be in the same folder. 

To make use of the library in your AIs, add the line:
        import("util.MinchinWeb", "MetaLib", 3);
    which will make the library available as the "MetaLib" class (or whatever
    you change that to).
    
-- Noteable Changes in Version 3 ----------------------------------------------
 * ShipPathfinder.BuildBuoys() will update the internally stored path if
      existing buoys are (re-)used
 * ShipPathfinder can now selectively skip its preliminary WaterBody Check
 * RoadPathfinder can now assign extra pathfinding costs to level crossings and
      drive thru road stations
 * RoadPathfinder can now bridge over canals, rivers, and railroad tracks!
       (thanks Zuu)
 
-- Version History ------------------------------------------------------------
Version 3 [2012-01-14]
    Minor update; released to coincide with the release of WmDOT v8
	Bug fixes and improvements to the Ship and Road Pathfinder
	Road Pathfinder can now bridge over canals, rivers, and railroads

Version 2 [2012-01-11]
    Major update; released to coincide with the release of WmDOT v7
    Added the Ship Pathfinder (v2), Line Walker (v1), and Atlas (v1) classes
    Added Constants, Station, Industry, and Marine (v1) class functions
    Updated Extras (v.2) and Arrays (v.3)
    
Version 1 [2011-04-28]
    Initial public release; released to coincide with the release of WmDOT v6
    Included Arrays v2, Extras v1, Road Pathfinder v7, Spiral Walker v2,
        and Waterbody Check v1

-- Roadmap --------------------------------------------------------------------
These are features I hope to add to MetaLibrary shortly. However, this is 
    subject to change without notice. However, I am open to suggestions!
v4      Road Pathfinder improvements (prebuild bridges and tunnels, upgrade
            bridges)
        Switch buoy and water depot building to Spiral Walker
		Import Logging interface from WmDOT
		Spiral Walker bug fixes
            
-- Known Issues ---------------------------------------------------------------
Pathfinding can take an exceptionally long time if there is no possible path.
    This is most often an issue when the two towns in question are on different
    islands.
SpiralWalker skips the tile [+1,0] relative to ths starting tile.

-- Help! It broke! (Bug Report) -----------------------------------------------
If MetaLibrary cause crashes, please help me fix it! Save a screenshot (under
    the ? on the far right of the in-game toolbar) and, if possible, the
    offending AI, and report the bug to either:
                            http://www.tt-forums.net/viewtopic.php?f=65&t=57903
                            http://code.google.com/p/openttd-noai-wmdot/issues/

-- Helpful Links --------------------------------------------------------------
Get OpenTTD!                                                    www.openttd.org
TT-Forums - all things Transport Tycoon related               www.tt-forums.net
MetaLibrary's thread on TT-Forums: release announcements, bug reports,
    suggetions, and general commentary
                            http://www.tt-forums.net/viewtopic.php?f=65&t=57903
WmDOT on Google Code: source code, and WmDOT: Bleeding Edge edition
                                    http://code.google.com/p/openttd-noai-wmdot
To report issues:            http://code.google.com/p/openttd-noai-wmdot/issues

My other projects (for OpenTTD):
    WmDOT (an AI)           http://www.tt-forums.net/viewtopic.php?f=65&t=53698
    Alberta Town Names      http://www.tt-forums.net/viewtopic.php?f=67&t=53313
    MinchinWeb's Random Town Name Generator
                            http://www.tt-forums.net/viewtopic.php?f=67&t=53579

-- Licence -------------------------------------------------------------------
MetaLibrary (unless otherwise noted) is licenced under a
    Creative Commons-Attribution 3.0 licence.

-- Included Functions ---------------------------------------------------------
Detailed descirptions of each of the function is given within the code files.
    See them for further details of each function.

[Arrays.nut] v.3
    Array.Create1D(length)
         .Create2D(length, width)
         .Create3D(length, width, height)
         .ToString1D(InArray)
         .ToString2D(InArray)
            - this is useful to output an array to the debugging output
         .ContainedIn1D(InArray, SearchValue)
         .ContainedIn2D(InArray, SearchValue)
         .ContainedIn3D(InArray, SearchValue)
         .ContainedIn1DIn2D(InArray2D, SearchArray1D)
            - these return true or false, depending on if the value can be
                found
         .Find1D(InArray, SearchValue)
         .Find2D(InArray, SearchValue)
         .Find3D(InArray, SearchValue)
            - returns the location of the first time the SearchValue is found;
                the 1D version returns an interger, the 2D and 3D versions
                return an array with the indexes
         .RemoveValueAt(InArray, Index)
         .InsertValueAt(InArray, Index, Value)
         .ToStringTiles1D(InArrayOfTiles, ArrayLength = false)
            - this is useful to output an tile array to the debugging output
         .FindPairs(InArray2D, SearchValue1, SearchValue2)
         .ContainedInPairs(InArray2D, SearchValue1, SearchValue2)
            - The idea is to povide an array of pairs, and find out if
                SearchValue1 and SearchValue2 is listed as one of the pairs
         .Compare1D(InArray1D, TestArray1D)

[Atlas.nut] v.1
The Atlas takes sources (departs) and attractions (destinations) and then
    generates a heap of pairs sorted by rating. Ratings can be generated based
    on distance alone or can be altered by user defined ratings (e.g. industry
    productions or town populations).
    
    enum ModelType
    {
        ONE_D,
        DISTANCE_MANHATTAN,
        DISTANCE_SHIP,
        DISTANCE_AIR,
        DISTANCE_NONE,
        ONE_OVER_T_SQUARED,
    }

    Atlas()
    Atlas.Reset()
            - Resets the Atlas (dumps all entered data)
        .AddSource(Source, Priority)
            - Adds a source to the sources list with the given priority
            - Assumes Source to be a TileIndex
        .AddAttraction(Attraction, Priority)
            - Adds an attraction to the attraction list with the given priority
            - Assumes Source to be a TileIndex
        .AddBoth(AddedTile, Priority)
            - Adds a tile to the BOTH the sources list and the attractions
                list with the (same) given priority
        .RunModel()
            - Takes the provided sources and destinations and runs the
                selected traffic model, populating the 'pairs' heap
        .Pop()
            - Returns the top rated pair as an array and removes the pair from
                the model
        .Peek()
            - Returns the top rated pair (as an array) but DOES NOT remove the
                pair from the model
        .Count()
            - Returns the amount of items currently in the list.
        .Exists
            - Check if an item exists in the list. Returns true/false.
        .SetModel(newmodel)
            - Sets the model type to the provided type
        .GetModel()
            - Returns the current model type (as the enum)
        .PrintModelType(ToPrint)
            - given a ModelType, returns the string equivalent
        .ApplyTrafficModel(StartTile, StartPriority, EndTile, EndPriority,
                Model)
            - Given the start and end points, applies the traffic model and
                returns the weighting (Smaller weightings are considered better)
            - This function is indepedant of the model/class, so is useful if
                you want to apply the traffic model to a given set of points. It
                is what is called internally to apply the model
        .SetMaxDistance(distance = -1)
            - Sets the maximum distance between sources and attractions to be
                included in the model
            - Negative values remove the limit
        .SetMaxDistanceModel(newmodel)
            - Sets the model type to the provided type
            - Used to calculate the distance between the source and attraction
                for applying maxdistance
            - DISTANCE_NONE is invalid. Use MinchinWeb.Atlas.SetMaxDistance(-1)
                instead.
            - ONE_OVER_T_SQUARED is invalid.
         
[Extras.nut] v.2
    Constants.Infinity() - returns 10,000
             .FloatOffset() - returns 1/2000
             .Pi() - returns 3.1415...
             .e() - returns 2.7182...
             .IndustrySize() - returns 4
             .InvalidIndustry() - returns 0xFFFF (65535)
             .InvalidTile() - returns 0xFFFFFF
             .MaxStationSpread() - returns the maximum station spread
             .BuoyOffset() - returns 3
             .WaterDepotOffset() - return 4
        
    Extras.SignLocation(text)
            - Returns the tile of the first instance where the sign matches the
                given text
          .MidPoint(TileA, TileB)
          .Perpendicular(SlopeIn)
          .Slope(TileA, TileB)
          .Within(Bound1, Bound2, Value)
          .WithinFloat(Bound1, Bound2, Value)
          .MinAbsFloat(Value1, Value2)
          .MaxAbsFloat(Value1, Value2)
          .AbsFloat(Value)
            - Returns the absolute Value as a floating number if one is
                provided
          .Sign(Value)
            - Returns +1 if the Value >= 0, -1 Value < 0
          .MinFloat(Value1, Value2)
          .MaxFloat(Value1, Value2)
          .MinAbsFloatKeepSign(Value1, Value2)
          .MaxAbsFloatKeepSign(Value1, Value2)
          .NextCardinalTile(StartTile, TowardsTile)
            - Given a StartTile and a TowardsTile, will given the tile
                immediately next(Manhattan Distance == 1) to StartTile that is
                closests to TowardsTile
                
    Industry.GetIndustryID(Tile)
            - AIIndustty.GetIndustryID( AIIndustry.GetLocation(IndustryID) )
                sometimes fails because GetLocation() returns the northmost
                tile of the industry which may be a dock, heliport, or not
                part of the industry at all.
            - This function starts at the tile, and then searchs a square out
            (up to Constants.StationSize) until it finds a tile with a valid
            TileID.

    Station.IsCargoAccepted(StationID, CargoID)
            - Checks whether a certain Station accepts a given cargo
            - Returns null if the StationID or CargoID are invalid
            - Returns true or false, depending on if the cargo is accepted
  
[Line.Walker.nut] v.1
The LineWalker class allows you to define a starting and endpoint, and then
    'walk' all the tiles between the two. Alternately, you can give a starting
    point and a slope.
    
    LineWalker()
    LineWalker.Start(Tile)
            - Sets the starting tile for LineWalker
        .End(Tile)
            - Sets the ending tile for LineWalker
            - If the slope is also directly set, the start and end tiles
                define a bounding box
        .Slope(Slope)
            - Sets the slope for LineWalker
            - Assumes that the slope is in the first or second quadrant unless
                ThirdQuadrant == true
        .Reset()
            - Resets the variables for the LineWalker
        .Restart()
            - Moves the LineWalker to the orginal starting position
        .Walk()
            - 'Walks' the LineWalker one tile at a tile
        .IsEnd()
            - Returns true if we are at the edge of the bounding box defined
                by the Starting and Ending point
        .GetStart()
            - Returns the tile set as the LineWalker start
        .GetEnd()
            - Returns the tile set as the LineWalker end
 
[Marine.nut] v.1
    Ship.DistanceShip(TileA, TileB)
            - Assuming open ocean, ship in OpenTTD will travel 45° angle where
                possible, and then finish up the trip by going along a
                cardinal direction
        .GetPossibleDockTiles(IndustryID)
            - Given an industry (by IndustryID), searches for possible tiles to
                build a dock and returns the list as an array of TileIndexs
            - Tiles given should be checked to ensure that the desired cargo is
                still accepted
        .GetDockFrontTiles(Tile)
            - Given a tile, returns an array of possible 'front' tiles that a
                ship could access the dock from
            - Can be either the land tile of a dock, or the water tile
            - Does not test if there is currently a dock at the tile
            - Might do funny things if the tile given is next to a river (i.e.
                a flat tile next to a water tile)
        .BuildBuoy(Tile)
            - Attempts to build a buoy, but first checks the box within
                MinchinWeb.Constants.BuoyOffset() for an existing buoy, and
                makes sure there's nothing but water between the two. If no
                existing buoy is found, one is built.
            - Returns the location of the existing or built bouy.
            - This will fail if the Tile given is a dock (or any tile that
                is not a water tile)
        .BuildDepot(DockTile, Front)
            - Attempts to build a (water) depot, but first checks the box
                within Constants.WaterDepotOffset() for an existing depot, and
                makes sure there's nothing but water between the depot and
                dock. If no existing depot is found, one is built.
            - Returns the location of the existing or built depot.
            - This will fail if the DockTile given is a dock (or any tile that
                is not a water tile)
 
[Pathfinder.Road.nut] v.8 - Updated
This file is licenced under the originl licnese - LGPL v2.1
    and is based on the NoAI Team's Road Pathfinder v3
The pathfinder uses the A* search pattern and includes functions to find the
    path, determine its cost, and build it.
    
    RoadPathfinder.InitializePath(sources, goals)
            - Set up the pathfinder
        .FindPath(iterations)    
            - Run the pathfinder; returns false if it isn't finished the path
                if it has finished, and null if it can't find a path
        .Cost.[xx]
            - Allows you to set or find out the pathfinder costs directly. See
                the function for valid entries
        .Info.GetVersion()
             .GetMinorVersion()
             .GetRevision()
             .GetDate()
             .GetName()
                - Useful for check provided version or debugging screen output
        .PresetOriginal()
        .PresetPerfectPath()
        .PresetQuickAndDirty()
        .PresetCheckExisting()
        .PresetMode6()
        .PresetStreetcar() 
            - Presets for the pathfinder parameters
        .GetBuildCost()
            - How much would it be to build the path?
        .BuildPath()
            - Build the path
        .GetPathLength()
            - How long is the path? (in tiles)
        .LoadPath(Path)
            - Provide your own path
        .GetPath()
            - Returns the path stored by the pathfinder
        .InitializePathOnTowns(StartTown, EndTown)
            - Initializes the pathfinder using the seed tiles of the given towns    
        .PathToTilePairs()
            - Returns a 2D array that has each pair of tiles that path joins
        .TilesPairsToBuild()
            - Similar to PathToTilePairs(), but only returns those pairs where
                there isn't a current road connection

[Pathfinder.Ship.nut] v.3 - Updated
The ship pathfinder takes two water tiles, checks that they are in the same
    waterbody, adn then returns an array of tiles that a ship would have to
    travel via to travel from one to the other.
    
    ShipPathfinder.InitializePath(source, goal)
            - is provided with a single source and single goal tile (but both
                are supplied as arrays)
        .Info.GetVersion()
            .GetRevision()
            .GetDate()
            .GetName()
        .Cost.[xx]
            - Allows you to set or find out the pathfinder costs directly. See
                the function for valid entries
        .FindPath(iterations)
            - Run the pathfinder; returns false if it isn't finished the path
                if it has finished, and null if it can't find a path
        .LandHo(TileA, TileB)
            - walks between the two tiles and returns a two item array
                containing the first land tile hit from either direction
        .WaterHo(StartTile, Slope, ThirdQuadrant = false)
            - Starts at a given tile and then walks out at the given slope
                until it hits water
            - "ThirdQuadrant" refers to whether to search the first and second
                quadrants (0°-90°, 271°-359°) or the third and fourth
                quadrants (91°-270°) 
            - LandHo() and WaterHo() are static functions and thus likely to be
                moved to a different sublibrary in the near future
        .GetPathLength()
            - Runs over the path to determine its length
        .CountPathBuoys()
            - Returns the number of potential buoys that may need to be built
        .BuildPathBuoys()
		    - Build the buoys that may need to be built
            - changes the internal storage of the path to be the list of these
                buoys
        .GetPath()
            - Returns the path, as currently held by the pathfinder		
                
[Spiral.Walker.nut] v.2
The SpiralWalker class allows you to define a starting point, and then 'walk'
    all the tiles in a spiral outward. It was originally used to find a
    buildable spot for my HQ in WmDOT, but is useful for many other things as
    well.
    
    .SpiralWalker()
    .SpiralWalker.Start(Tile)
            - Sets the starting tile for SpiralWalker
        .Reset()
            - Clears all data within the SprialWalker
        .Restart()
            - Sends the SpiralWalker back to the starting tile
        .Walk()
            - Move out, one tile at a time. Returns the Tile the SpiralWalker
                is on
        .GetStart()
            - Returns the tile the SpiralWalker is starting on
        .GetStage()
            - Returns the Stage the SpiralWalker is on (basically, the line
                segments its completed plus one; it takes four to complete a revolution)
        .GetTile()
            - Returns the Tile the SpiralWalker is on
        .GetStep()
            - Returns the number of steps the SpiralWalker has done
        
[Waterbody.Check.nut] v.1
Waterbody check is in effect a specialized pathfinder. It serves to check
    whether two points are in the same waterbody (i.e. a ship could travel
    between them). It is optimized to run extremely fast (I hope!). It can be
    called separately, but was originally designed as a pre-run check for my
    Ship Pathfinder (not quite finished, but to also be included in this
    MetaLibrary).
        
    WaterbodyCheck.InitializePath(sources, goals)
            - Set up the pathfinder
            - source and goals must be arrays
        .FindPath(iterations)    
            - Run the pathfinder; returns false if it isn't finished the path
                if it has finished, and null if it can't find a path
        .Cost.[xx]
            - Allows you to set or find out the pathfinder costs directly. See
                the function for valid entries
        .GetPathLength()
            - Runs over the path to determine its length
        .PresetSafety(Start, End)
            - Caps the pathfinder as twice the Manhattan distance between the
                two tiles
            - source and goals must be integers (TileIndexes)
