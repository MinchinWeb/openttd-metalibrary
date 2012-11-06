/*	SpiralWalker class v.2-GS r.140 [2011-12-03],
 *		part of MinchinWeb's MetaLibrary v.2-GS, r.140 [2011-12-03],
 *		adapted from Minchinweb's MetaLibrary v.1, r.112, [2011-04-26],
 *		originally part of WmDOT v.5
 *	Copyright © 2011 by W. Minchin. For more info,
 *		please visit http://openttd-noai-wmdot.googlecode.com/
 */
 
/*	The SpiralWalker class allows you to define a starting point, and then
 *		'walk' all the tiles in a spiral outward. It was originally used to 
 *		find a buildable spot for my HQ in WmDOT, but is useful for many other
 *		things as well.
 */
 
/*	Functions provided:
 *		MetaLib.SpiralWalker()
 *		MetaLib.SpiralWalker.Start(Tile)
 *							.Reset()
 *							.Restart()
 *							.Walk()
 *							.GetStart()
 *							.GetStage()
 *							.GetStep() 
 */
 
/*	Known Issues:
 *	- SpiralWalker skips the tile [+1,0] relative to ths starting tile
 */
 
class _MinchinWeb_SW_ {
	_start = null;
	_startx = null;
	_starty = null;
	_x = null;
	_y = null;
	_current_tile = null;
	_dx = null;
	_dy = null;
	_Steps = null;
	_Stage = null;
	_StageMax = null;
	_StageSteps = null;
	
	constructor()
	{
	this._dx = -1;
	this._dy =  0;
	this._Steps = 0;
	this._Stage = 1;
	this._StageMax = 1;
	this._StageSteps = 0;
	}
}

function _MinchinWeb_SW_::Start(Tile)
{
//	Sets the starting tile for SpiralWalker
	this._start = Tile;
	this._startx = GSMap.GetTileX(Tile);
	this._starty = GSMap.GetTileY(Tile);
	this._x = this._startx;
	this._y = this._starty;
	this._current_tile = this._start;
	
	this._dx = -1;
	this._dy =  0;
	this._Steps = 0;
//	this._Stage = 1;
	this._Stage = 1;
	this._StageMax = 1;
	this._StageSteps = 0;
}

function _MinchinWeb_SW_::Reset()
{
	this._start = null;
	this._startx = null;
	this._starty = null;
	this._x = null;
	this._y = null;
	this._current_tile = null;
}

function _MinchinWeb_SW_::Restart()
{
	this._x = this._startx;
	this._y = this._starty;
	this._current_tile = this._start;
	
	this._dx = -1;
	this._dy =  0;
	this._Steps = 0;
	this._Stage = 1;
	this._StageMax = 1;
	this._StageSteps = 0;
}

function _MinchinWeb_SW_::Walk()
{
	this._x += this._dx;
	this._y += this._dy;
	this._StageSteps ++;
	this._Steps ++;
	
	// Check if it's time to turn
	if (this._StageSteps == this._StageMax) {
		this._StageSteps = 0;
		if (this._Stage % 2 == 0) {
			this._StageMax++;
		}
		this._Stage ++;
		
		// Turn Clockwise
		switch (this._dx) {
			case 0:
				switch (this._dy) {
					case -1:
						this._dx = -1;
						this._dy =  0;
						break;
					case 1:
						this._dx = 1;
						this._dy = 0;
						break;
				}
				break;
			case -1:
				this._dx = 0;
				this._dy = 1;
				break;
			case 1:
				this._dx =  0;
				this._dy = -1;
				break;
		}
	}

//	GSLog.Info("     SpiralWalker.Walk: " + this._dx + " " + this._dy + " : " + this._Steps + " " + this._Stage + " " + this._StageSteps + " " + this._StageMax);
	this._current_tile = GSMap.GetTileIndex(this._x, this._y);
	return this._current_tile;
}

function _MinchinWeb_SW_::GetStart()
{
//	Returns the tile the SpiralWalker is starting on
	return this._start;
}

function _MinchinWeb_SW_::GetStage()
{
//	Returns the Stage ths SpiralWalker is on (basically, the line segments its
//		completed plus one; it takes four to complete a revolution)
	return this._Stage;
}

function _MinchinWeb_SW_::GetTile()
{
//	Returns the Tile ths SpiralWalker is on
	return this._current_tile;
}

function _MinchinWeb_SW_::GetStep()
{
//	Returns the number of steps ths SpiralWalker has done
	return this._Steps;
}