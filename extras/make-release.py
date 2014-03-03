#! python27
# -*- coding: utf-8 -*-

#	Minchinweb's MetaLibrary v.7 [2014-02-28],  
#	Copyright © 2011-14 by W. Minchin. For more info,
#		please visit https://github.com/MinchinWeb/openttd-metalibrary
#
#	Permission is granted to you to use, copy, modify, merge, publish, 
#	distribute, sublicense, and/or sell this software, and provide these 
#	rights to others, provided:
#
#	+ The above copyright notice and this permission notice shall be included
#		in all copies or substantial portions of the software.
#	+ Attribution is provided in the normal place for recognition of 3rd party
#		contributions.
#	+ You accept that this software is provided to you "as is", without warranty.
#

"""This script is a Python script to generate a tar file of MetaLibrary for
upload to BaNaNaS. v2 [2014-03-03]"""

import os
from os.path import join
import tarfile
import winshell
import fileinput
import re

SourceDir = join ("..")
OutputDir = join ("..", "releases")

# multiple replacement
# from 	http://stackoverflow.com/questions/6116978/python-replace-multiple-strings
#
# Usage:
# >>> replacements = (u"café", u"tea"), (u"tea", u"café"), (u"like", u"love")
# >>> print multiple_replace(u"Do you like café? No, I prefer tea.", *replacements)
# Do you love tea? No, I prefer café.
def multiple_replacer(*key_values):
    replace_dict = dict(key_values)
    replacement_function = lambda match: replace_dict[match.group(0)]
    pattern = re.compile("|".join([re.escape(k) for k, v in key_values]), re.M | re.I)
    return lambda string: pattern.sub(replacement_function, string)

def multiple_replace(string, *key_values):
    return multiple_replacer(*key_values)(string)

mdReplacements =	('%MinchinWeb', 'MinchinWeb'), \
					('\_', '_'), \
					('←', '<-')
					
aiReplacements = \
	('"queue.fibonacci_heap", "", 3);'	  ,'"queue.fibonacci_heap", "", 2' ), \
	('Fibonacci Heap v.3'				  ,'Fibonacci Heap v.2'			   ), \
	("AIAccounting"						  ,"GSAccounting"                  ), \
	("AIAirport"                          ,"GSAirport"                     ), \
	("AIBase"                             ,"GSBase"                        ), \
	("AIBaseStation"                      ,"GSBaseStation"                 ), \
	("AIBridge"                           ,"GSBridge"                      ), \
	("AIBridgeList"                       ,"GSBridgeList"                  ), \
	("AIBridgeList_Length"                ,"GSBridgeList_Length"           ), \
	("AICargo"                            ,"GSCargo"                       ), \
	("AICargoList"                        ,"GSCargoList"                   ), \
	("AICargoList_IndustryAccepting"      ,"GSCargoList_IndustryAccepting" ), \
	("AICargoList_IndustryProducing"      ,"GSCargoList_IndustryProducing" ), \
	("AICargoList_StationAccepting"       ,"GSCargoList_StationAccepting"  ), \
	("AICompany"                          ,"GSCompany"                     ), \
	("AIController"                       ,"GSController"                  ), \
	("AIDate"                             ,"GSDate"                        ), \
	("AIDepotList"                        ,"GSDepotList"                   ), \
	("AIEngine"                           ,"GSEngine"                      ), \
	("AIEngineList"                       ,"GSEngineList"                  ), \
	("AIError"                            ,"GSError"                       ), \
	("AIEvent"                            ,"GSEvent"                       ), \
	("AIEventAircraftDestTooFar"          ,"GSEventAircraftDestTooFar"     ), \
	("AIEventCompanyAskMerger"            ,"GSEventCompanyAskMerger"       ), \
	("AIEventCompanyBankrupt"             ,"GSEventCompanyBankrupt"        ), \
	("AIEventCompanyInTrouble"            ,"GSEventCompanyInTrouble"       ), \
	("AIEventCompanyMerger"               ,"GSEventCompanyMerger"          ), \
	("AIEventCompanyNew"                  ,"GSEventCompanyNew"             ), \
	("AIEventCompanyTown"                 ,"GSEventCompanyTown"            ), \
	("AIEventController"                  ,"GSEventController"             ), \
	("AIEventDisasterZeppelinerCleared"   ,"GSEventDisasterZeppelinerCleared"), \
	("AIEventDisasterZeppelinerCrashed"   ,"GSEventDisasterZeppelinerCrashed"), \
	("AIEventEngineAvailable"             ,"GSEventEngineAvailable"        ), \
	("AIEventEnginePreview"               ,"GSEventEnginePreview"          ), \
	("AIEventExclusiveTransportRights"    ,"GSEventExclusiveTransportRights"), \
	("AIEventIndustryClose"               ,"GSEventIndustryClose"          ), \
	("AIEventIndustryOpen"                ,"GSEventIndustryOpen"           ), \
	("AIEventRoadReconstruction"          ,"GSEventRoadReconstruction"     ), \
	("AIEventStationFirstVehicle"         ,"GSEventStationFirstVehicle"    ), \
	("AIEventSubsidyAwarded"              ,"GSEventSubsidyAwarded"         ), \
	("AIEventSubsidyExpired"              ,"GSEventSubsidyExpired"         ), \
	("AIEventSubsidyOffer"                ,"GSEventSubsidyOffer"           ), \
	("AIEventSubsidyOfferExpired"         ,"GSEventSubsidyOfferExpired"    ), \
	("AIEventTownFounded"                 ,"GSEventTownFounded"            ), \
	("AIEventVehicleCrashed"              ,"GSEventVehicleCrashed"         ), \
	("AIEventVehicleLost"                 ,"GSEventVehicleLost"            ), \
	("AIEventVehicleUnprofitable"         ,"GSEventVehicleUnprofitable"    ), \
	("AIEventVehicleWaitingInDepot"       ,"GSEventVehicleWaitingInDepot"  ), \
	("AIExecMode"                         ,"GSExecMode"                    ), \
	("AIGameSettings"                     ,"GSGameSettings"                ), \
	("AIGroup"                            ,"GSGroup"                       ), \
	("AIGroupList"                        ,"GSGroupList"                   ), \
	("AIIndustry"                         ,"GSIndustry"                    ), \
	("AIIndustryList"                     ,"GSIndustryList"                ), \
	("AIIndustryList_CargoAccepting"      ,"GSIndustryList_CargoAccepting" ), \
	("AIIndustryList_CargoProducing"      ,"GSIndustryList_CargoProducing" ), \
	("AIIndustryType"                     ,"GSIndustryType"                ), \
	("AIIndustryTypeList"                 ,"GSIndustryTypeList"            ), \
	("AIInfo"                             ,"GSInfo"                        ), \
	("AIInfrastructure"                   ,"GSInfrastructure"              ), \
	("AILibrary"						  ,"GSLibrary"					   ), \
	("AIList"                             ,"GSList"                        ), \
	("AILog"                              ,"GSLog"                         ), \
	("AIMap"                              ,"GSMap"                         ), \
	("AIMarine"                           ,"GSMarine"                      ), \
	("AIOrder"                            ,"GSOrder"                       ), \
	("AIRail"                             ,"GSRail"                        ), \
	("AIRailTypeList"                     ,"GSRailTypeList"                ), \
	("AIRoad"                             ,"GSRoad"                        ), \
	("AISign"                             ,"GSSign"                        ), \
	("AISignList"                         ,"GSSignList"                    ), \
	("AIStation"                          ,"GSStation"                     ), \
	("AIStationList"                      ,"GSStationList"                 ), \
	("AIStationList_Vehicle"              ,"GSStationList_Vehicle"         ), \
	("AISubsidy"                          ,"GSSubsidy"                     ), \
	("AISubsidyList"                      ,"GSSubsidyList"                 ), \
	("AITestMode"                         ,"GSTestMode"                    ), \
	("AITile"                             ,"GSTile"                        ), \
	("AITileList"                         ,"GSTileList"                    ), \
	("AITileList_IndustryAccepting"       ,"GSTileList_IndustryAccepting"  ), \
	("AITileList_IndustryProducing"       ,"GSTileList_IndustryProducing"  ), \
	("AITileList_StationType"             ,"GSTileList_StationType"        ), \
	("AITown"                             ,"GSTown"                        ), \
	("AITownEffectList"                   ,"GSTownEffectList"              ), \
	("AITownList"                         ,"GSTownList"                    ), \
	("AITunnel"                           ,"GSTunnel"                      ), \
	("AIVehicle"                          ,"GSVehicle"                     ), \
	("AIVehicleList"                      ,"GSVehicleList"                 ), \
	("AIVehicleList_DefaultGroup"         ,"GSVehicleList_DefaultGroup"    ), \
	("AIVehicleList_Depot"                ,"GSVehicleList_Depot"           ), \
	("AIVehicleList_Group"                ,"GSVehicleList_Group"           ), \
	("AIVehicleList_SharedOrders"         ,"GSVehicleList_SharedOrders"    ), \
	("AIVehicleList_Station"              ,"GSVehicleList_Station"         ), \
	("AIWaypoint"                         ,"GSWaypoint"                    ), \
	("AIWaypointList"                     ,"GSWaypointList"                ), \
	("AIWaypointList_Vehicle"             ,"GSWaypointList_Vehicle"        )


# find version
version = 0
with open(join(SourceDir, "library.nut"), 'r') as VersionFile:
	for line in VersionFile:
		if 'GetVersion()' in line:
			version = line[line.find("return") + 6 : line.find(";")].strip()

# Create AI version
MetaLibVersion = "MetaLib-" + version
TarFileName = join(OutputDir, MetaLibVersion + "-AI.tar")
MyTarFile = tarfile.open(name=TarFileName, mode='w')
for File in os.listdir(SourceDir):
	if os.path.isfile(join(SourceDir, File)):
		if File.endswith(".nut"):
			MyTarFile.add(join(SourceDir, File), join(MetaLibVersion, File))
		elif File.endswith(".txt"):
			MyTarFile.add(join(SourceDir, File), join(MetaLibVersion, File))
		elif File.endswith(".md"):
			# create temp copy
			winshell.copy_file(join(SourceDir, File), File, rename_on_collision=False)
			for line in fileinput.input(File, inplace=1):
				# replace the characters escaped for dOxygen
				print multiple_replace(line, *mdReplacements),
			MyTarFile.add(File, join(MetaLibVersion, File[:-3] + ".txt"))
			winshell.delete_file(File, no_confirm=True, allow_undo=False)							
MyTarFile.close()

print ("    " + MetaLibVersion + "-AI.tar created!")

# Create GameScript version
LineCount = 0
TarFileName = join(OutputDir, MetaLibVersion + "-GS.tar")
MyTarFile = tarfile.open(name=TarFileName, mode='w')
for File in os.listdir(SourceDir):
	if os.path.isfile(join(SourceDir, File)):
		if File.endswith(".nut"):
			winshell.copy_file(join(SourceDir, File), File, rename_on_collision=False)
			for line in fileinput.input(File, inplace=1):
				# replace the AI API with GS API
				print multiple_replace(line, *aiReplacements),
				LineCount++
			MyTarFile.add(File, join(MetaLibVersion, File))
			winshell.delete_file(File, no_confirm=True, allow_undo=False)
		elif File.endswith(".txt"):
			MyTarFile.add(join(SourceDir, File), join(MetaLibVersion, File))
		elif File.endswith(".md"):
			# create temp copy
			winshell.copy_file(join(SourceDir, File), File, rename_on_collision=False)
			for line in fileinput.input(File, inplace=1):
				# replace the characters escaped for dOxygen
				print multiple_replace(line, *mdReplacements),
				LineCount++
			MyTarFile.add(File, join(MetaLibVersion, File[:-3] + ".txt"))
			winshell.delete_file(File, no_confirm=True, allow_undo=False)
MyTarFile.close()

print ("    " + MetaLibVersion + "-GS.tar created!")
print ("        " + LineCount + " lines of code")
