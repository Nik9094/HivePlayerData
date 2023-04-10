/*
 * Custom functions for handling DeathRun world records / leaderboards.
 * Checks if the list of maps and their relative speedrun.com ID's are saved in the program's folder "resources"
 * Aswell as checking if it's updated. Everything is handled as txt or json files. 
 * The data comes from RoccoDev's website.
 * MODIFYING THIS CODE OR THE FILES CREATED MAY CAUSE ISSUES.
 * Made by Nik9094.
 * Installation:
 * 		#Include .\libs\DeathRunWR.ahk		in main code; after using "SetWorkingDir %A_ScriptDir%"
 * Call method:
 * 		DRtimeLeads.func()					replace func as needed.
 */

	
class DRtimeLeads {

	checkMapsFile() {		;Checks and eventually updates the list of ID's for each map - updates depend on RoccoDev's website.
		if !FileExist(".\resources\DeathRunMaps.json") {
			UrlDownloadToFile, https://rocco.dev/beezighosting/files/dr.json, .\resources\DeathRunMaps.json
		} else {
			UrlDownloadToFile, https://rocco.dev/beezighosting/files/dr.json, .\resources\newList.json		;Download list to compare
			currentMaps := FileOpen(".\resources\DeathRunMaps.json", "rw")
			newMaps := FileOpen(".\resources\newList.json", "r")
			if !(currentMaps.read() = newMaps.read()) {		;if different
				currentMaps.length := 0
				newMaps.seek(0)
				currentMaps.write(newMaps.read())
				FileDelete, .\resources\newList.json		;delete because not needed anymore
			} else {
				FileDelete, .\resources\newList.json		;delete because not needed
			}
		}
	}

	
	FormatIndividualRecords(time) {
		mins := Floor(time / 60)
		if (mins >= 60)
			mins := mins - 60
		secs := Mod(time, 60)
		mins := SubStr("0" . mins, -1)
		secs := SubStr("0" . secs, -1)
		return time := mins . ":" . secs
	}
	
	ShowPlayerTimes() {
		dataFull := JSON.Load(FileOpen(".\resources\DeathRunMaps.json", "r").read())
		For key, values in dataFull
		{
			apiName := values.api
			Time := this.FormatIndividualRecords(GameStat.maprecords[apiName])
			text .= key ": " Time "`n"
		}
		GuiControl,, DisplayText, % text
	}
}