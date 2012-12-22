/*	Dominion Land System Roads v.1 [2012-12-21],
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
	function GetVersion()       { return 1; }
	function GetRevision()		{ return 0; }
	function GetDate()          { return "2012-12-21"; }
	function GetName()          { return "Dominion Land System Road"; }
	
	_gridx = null;		///< Grid spacing in x direction
	_gridy = null;		///< Grid spacing in y direction
	_datum = null;		///< This is the 'center' of our survey system
	_basedatum = null;	///< this is the 'grid point' closest to 0,0
	
	constructor() {
		this._gridx = 8;
		this._gridy = 8;
		_datum = 0;
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

function _MinchinWeb_DLS_::GridPoints(End1, End2) {
//	## GridPoints
//	Returns an array of TileIndexs that are 'grid points' or where roads will
//	have intersections.  
//	*End1* and *End2* are expected to be TileIndex'es
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
		y2 = tempx;
	}

	_MinchinWeb_Log_.Note("Generating grid points from " + x1 + ", " + y1 + " to " + x2 + ", " + y2, 5);

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
			MyArray.push(AIMap.GetTileIndex(workingx, workingy));
			_MinchinWeb_Log_.Note("Add grid point at " + workingx + ", " + workingy, 7)
			workingy = workingy + this._gridy;
		} while (workingy < y2);
		workingx = workingx + this._gridx;
		workingy = starty;
	} while (workingx < x2);

	_MinchinWeb_Log_.Note("Generated " + MyArray.len() + " grid points.", 5);
	return MyArray;

}

function _MinchinWeb_DLS_::AllGridPoints() {
//	Returns an array of all the 'grid points' on the map
	return _MinchinWeb_DLS_.GridPoints(AIMap.GetTileIndex(1,1), AIMap.GetTileIndex(AIMap.GetMapSizeX() - 2, AIMap.GetMapSizeY() - 2));
}
