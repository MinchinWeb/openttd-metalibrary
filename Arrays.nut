/*	Array SubLibrary, v.3 r.189 [2012-01-05],
 *		part of Minchinweb's MetaLibrary v2,
 *		originally part of WmDOT v.5  r.53d	[2011-04-09]
 *			and WmArray library v.1  r.1 [2011-02-13].
 *	Copyright © 2011-12 by W. Minchin. For more info,
 *		please visit http://openttd-noai-wmdot.googlecode.com/
 */

/*	Provided functions:
 *		MetaLib.Array.Create1D(length)
 *					 .Create2D(length, width)
 *					 .Create3D(length, width, height)
 *					 .ToString1D(InArray)
 *					 .ToString2D(InArray)
 *					 .ContainedIn1D(InArray, SearchValue)
 *					 .ContainedIn2D(InArray, SearchValue)
 *					 .ContainedIn3D(InArray, SearchValue)
 *					 .ContainedIn1DIn2D(InArray2D, SearchArray1D)
 *					 .Find1D(InArray, SearchValue)
 *					 .Find2D(InArray, SearchValue)
 *					 .Find3D(InArray, SearchValue)
 *					 .RemoveValueAt(InArray, Index)
 *					 .InsertValueAt(InArray, Index, Value)
 *					 .ToStringTiles1D(InArrayOfTiles, ArrayLength = false)
 *					 .FindPairs(InArray2D, SearchValue1, SearchValue2)
 *					 .ContainedInPairs(InArray2D, SearchValue1, SearchValue2)
 *					 .Compare1D(InArray1D, TestArray1D)
 */
 
//	To-DO
//		- add safety if an array is not provided
 
class _MinchinWeb_Array_ {
	main = null;
}

function _MinchinWeb_Array_::Create1D(length)
{
    return array[length];
}

function _MinchinWeb_Array_::Create2D(length, width)
{
    local ReturnArray = [length];
    local tempArray = [width];
    for (local i=0; i < length; i++) {
        ReturnArray[i] = tempArray;
    }
    
    return ReturnArray;
}

function _MinchinWeb_Array_::Create3D(length, width, height)
{
    local ReturnArray = [length];
    local tempArray = [width];
    local tempArray2 = [height];
    
    for (local i=0; i < width; i++) {
        tempArray[i] = tempArray2;
    }
    
    for (local i=0; i < length; i++) {
        ReturnArray[i] = tempArray;
    }
    
    return ReturnArray;
}

function _MinchinWeb_Array_::ToString1D(InArray)
{
	//	Add error check that an array is provided
	
	if (InArray == null) {
		return null;
	} else {
		local Length = InArray.len();
		local i = 0;
		local Temp = "";
		while (i < InArray.len() ) {
			Temp = Temp + "  " + InArray[i];
			i++;
		}
		return ("The array is " + Length + " long.  " + Temp + " ");
	}
}

function _MinchinWeb_Array_::ToString2D(InArray)
{
	//	Add error check that a 2D array is provided

	if (InArray == null) {
		return null;
	} else {
		local Length = InArray.len();
		local i = 0;
		local Temp = "";
		while (i < InArray.len() ) {
			local InnerArray = [];
			InnerArray = InArray[i];
			local InnerLength = InnerArray.len();
			local j = 0;
			while (j < InnerArray.len() ) {
				Temp = Temp + "  " + InnerArray[j];
				j++;
			}
			Temp = Temp + "  /  ";
			i++;
		}
		return ("The array is " + Length + " long." + Temp + " ");
	}
}

function _MinchinWeb_Array_::ContainedIn1D(InArray, SearchValue)
{
//	Searches the array for the given value. Returns 'TRUE' if found and
//		'FALSE' if not.
//	Accepts 1D Arrays

	if (InArray == null) {
		return null;
	} else {
		for (local i = 0; i < InArray.len(); i++ ) {
				if (InArray[i] == SearchValue) {
					return true;
				}
		}
		return false;
	}
}

function _MinchinWeb_Array_::ContainedIn2D(InArray, SearchValue)
{
//	Searches the array for the given value. Returns 'TRUE' if found and
//		'FALSE' if not.
//	Accepts 2D Arrays
//	Note that using this to see if an given array is an element of the parent
//		array does not seem to be returning expected results. Use
//		ContainedInPairs(InArray2D, SearchValue1, SearchValue2) instead. 

	if (InArray == null) {
		return null;
	} else {
		for (local i = 0; i < InArray.len(); i++ ) {
			for (local j=0; j < InArray[i].len(); j++ ) {
				if (InArray[i][j] == SearchValue) {
					return true;
				}
			}
		}
		return false;
	}
}

function _MinchinWeb_Array_::ContainedIn3D(InArray, SearchValue)
{
//	Searches the array for the given value. Returns 'TRUE' if found and
//		'FALSE' if not.
//	Accepts 3D Arrays

	if (InArray == null) {
		return null;
	} else {
		for (local i = 0; i < InArray.len(); i++ ) {
			for (local j=0; j < InArray[i].len(); j++ ) {
				for (local k=0; k < InArray[i].len(); k++)
					if (InArray[i][j][k] == SearchValue) {
						return true;
					}
			}
		}
		return false;
	}
}

function _MinchinWeb_Array_::ContainedIn1DIn2D(InArray2D, SearchArray1D)
{
//	Searches the array for the given array. Returns 'TRUE' if found and
//		'FALSE' if not.
//	Accepts 2D Arrays for InArray and 1D Array for SearchArray

	if (InArray2D == null) {
		return null;
	} else {
		for (local i = 0; i < InArray2D.len(); i++ ) {
			if (_MinchinWeb_Array_.Compare1D(InArray2D[i], SearchArray1D) == true) {
				return true;
			}
		}
		return false;
	}
}

function _MinchinWeb_Array_::Find1D(InArray, SearchValue)
{
//	Searches the array for the given value. Returns the index of the value if 
//		found and 'FALSE' if not. Will only return the index of the
//		first time the value is found.
//	Accepts 1D Arrays
//	Note that using this to see if an given array is an element of the parent
//		array does not seem to be returning expected results. Use
//		FindPairs(InArray2D, SearchValue1, SearchValue2) instead.

	if (InArray == null) {
		return null;
	} else {
		for (local i = 0; i < InArray.len(); i++ ) {
				if (InArray[i] == SearchValue) {
					return i;
				}
		}
		return false;
	}
}

function _MinchinWeb_Array_::Find2D(InArray, SearchValue)
{
//	Searches the array for the given value. Returns a 2-item array with the 
//		indexes if found and 'FALSE' if not. Will only return the index of the
//		first time the value is found.
//	Accepts 2D Arrays

	if (InArray == null) {
		return null;
	} else {
		for (local i = 0; i < InArray.len(); i++ ) {
			for (local j=0; j < InArray[i].len(); j++ ) {
				if (InArray[i][j] == SearchValue) {
					return [i, j];
				}
			}
		}
		return false;
	}
}

function _MinchinWeb_Array_::Find3D(InArray, SearchValue)
{
//	Searches the array for the given value. Returns a 3-item array with the 
//		indexes if found and 'FALSE' if not. Will only return the index of the
//		first time the value is found.
//	Accepts 3D Arrays

	if (InArray == null) {
		return null;
	} else {
		for (local i = 0; i < InArray.len(); i++ ) {
			for (local j=0; j < InArray[i].len(); j++ ) {
				for (local k=0; k < InArray[i].len(); k++)
					if (InArray[i][j][k] == SearchValue) {
						return [i,j,k];
					}
			}
		}
		return false;
	}
}

function _MinchinWeb_Array_::RemoveValueAt(InArray, Index)
{
//	Removes the value at the index, and shifts the rest of the array to the
//		left. The returned array is thus 1 shorter than the supplied array.
	local i = 0;
	local Return = [];
	
	for (i; i < Index; i++) {
		Return.push(InArray[i]);
	}
	i++;
	for (i; i < InArray.len(); i++) {
		Return.push(InArray[i]);
	}
	return Return;	
}

function _MinchinWeb_Array_::InsertValueAt(InArray, Index, Value)
{
//	Adds 'Value' to the 'InArray' at the given 'Index'. The rest of the array
//		is shift one place to the right. The returned array is thus 1 longer
//		than 'InArray'.
	local i = 0;
	local Return = [];
	
	for (i; i < Index; i++) {
		Return.push(InArray[i]);
	}
	Return.push(Value);
	for (i; i < InArray.len(); i++) {
		Return.push(InArray[i]);
	}
	return Return;	
}

function _MinchinWeb_Array_::ToStringTiles1D(InArrayOfTiles, ArrayLength = false)
{
	//	Add error check that an array is provided
	
	if (InArrayOfTiles == null) {
		return null;
	} else {
		local Length = InArrayOfTiles.len();
		local i = 0;
		local Temp = "";
		while (i < InArrayOfTiles.len() ) {
			Temp = Temp + "  " + AIMap.GetTileX(InArrayOfTiles[i]) + "," + AIMap.GetTileY(InArrayOfTiles[i]);
			i++;
		}
		if (ArrayLength == true) {
			return ("The array is " + Length + " long.  " + Temp + " ");
		} else {
			return Temp;
		}
	}
}

function _MinchinWeb_Array_::FindPairs(InArray2D, SearchValue1, SearchValue2)
{
//	Searches the array for the given pair of value. Returns a the index  
//		if found and 'FALSE' if not. Will only return the index of the
//		first time the value is found.
//	The idea is to povide an array of pairs, and find out if SearchValue1
//		and SearchValue2 is listed as one of the pairs
//	Accepts 2D Arrays

	if (InArray2D == null) {
		return null;
	} else {
		local Return1 = false;
		local Return2 = false;
		for (local i = 0; i < InArray2D.len(); i++ ) {
			for (local j=0; j < InArray2D[i].len(); j++ ) {
				if ((InArray2D[i][j] == SearchValue1) && !Return1) {
					Return1 = true;	
				} else if (InArray2D[i][j] == SearchValue2) {
					Return2 = true;	
				}
			}
			if (Return1 && Return2) {
				return i;
			} else {
				Return1 = false;
				Return2 = false;
			}
		}
		return false;
	}
}

function _MinchinWeb_Array_::ContainedInPairs(InArray2D, SearchValue1, SearchValue2)
{
//	Searches the array for the given pair of value. Returns a the index  
//		if found and 'FALSE' if not. Will only return the index of the
//		first time the value is found.
//	The idea is to povide an array of pairs, and find out if SearchValue1
//		and SearchValue2 is listed as one of the pairs
//	Accepts 2D Arrays

	if (InArray2D == null) {
		return null;
	} else {
		local Return1 = false;
		local Return2 = false;
		for (local i = 0; i < InArray2D.len(); i++ ) {
			for (local j=0; j < InArray2D[i].len(); j++ ) {
				if ((InArray2D[i][j] == SearchValue1) && !Return1) {
					Return1 = true;	
				} else if (InArray2D[i][j] == SearchValue2) {
					Return2 = true;	
				}
			}
			if (Return1 && Return2) {
				return true;
			} else {
				Return1 = false;
				Return2 = false;
			}
		}
		return false;
	}
}

function _MinchinWeb_Array_::Compare1D(InArray1D, TestArray1D)
{
//	Compares the two arrays item for item. Returns true if every item pair
//		matches.
//	I wrote this because I don't trust (InArray == TestArray) to work this
//		way...
	if (InArray1D.len() != TestArray1D.len() ) {
		return false;	
	}
	for (local i = 0; i < InArray1D.len(); i++) {
		if (InArray1D[i] != TestArray1D[i]) {
			return false;
		}
	}
	
	return true;
}