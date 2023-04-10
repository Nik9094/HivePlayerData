/*
 * Custom functions for the main code HivePlayerData.
 * Everything in here only works when requested by the main code.
 * Modifying any of the lines may result in breaking the whole program.
 * Made by nik9094. 
 * Installation:
 *  	#Include HiveUtils.ahk		in main code, if both files are in the same directory.
 * Call method:
 *  	var := Util.func(params)  	replace "var", "func" and "params" as needed. Calling this way gives a value or array of data.
 *		Util.func(params)			replace "func" and "params" as needed. Calling this way executes a set of commands.
 */
 
 	global hiveBase := "http://api.hivemc.com/v1/player/"		;base of Hive player statistics link.
	global monthlyBase := "https://api.rocco.dev/"			;base of Rocco's Monthly leaderboards link.
	global nextGUI							;saves the next GUI's label
	global GameLink							;saves the merged link from Link()
	global GameStat							;saves the full JSON string from APIRequest()
	global GameInfo							;saves variables above as an array
	global lineHeight = 40 						;Min height to display a single line for online statuses.
	global spacing = 60 						;add this height to keep good spacing for the online statuses.
	
class Util {		;every function falls under a this class
	
	getHiveLink(UUID, Game) {
		return HIVE := hiveBase . UUID . "/" . Game
	}
	
	getMonthlyLink(UUID, Game) {
		return MONTHLY := monthlyBase . Game . "/monthlies/profile/" . UUID
	}
	
	Back(whereTo) {							;to be executed when a "Go back" button is pressed on any window
		Gui, Destroy
		GoSub, %whereTo%
	}
	
	Game(UUID, GAME) {						;retrieves all data about a game
		switch GAME						;and saves it in an array
		{
		Case "General":
			Link := this.getHiveLink(UUID, "")
			GameStat := APIRequest(Link)
			nextGUI = GeneralStats
		Case "DeathRun":
			GameLink := this.getHiveLink(UUID, "dr")
			MonthLink := this.getMonthlyLink(UUID, "dr")
			LeadLink := this.getLeadRank(UUID, "dr")
			GameStat := APIRequest(GameLink)
			nextGUI = DRStats
		Case "BedWars":
			GameLink := this.getHiveLink(UUID, "BED")
			MonthLink := this.getMonthlyLink(UUID, "BED")
			LeadLink := this.getLeadRank(UUID, "BED")
			GameStat := APIRequest(GameLink)
			nextGUI = BEDStats
		Case "SkyWars":
			GameLink := this.getHiveLink(UUID, "sky")
			MonthLink := this.getMonthlyLink(UUID, "sky")
			LeadLink := this.getLeadRank(UUID, "sky")
			GameStat := APIRequest(GameLink)
			nextGUI = SKYStats
		Case "Trouble in Mineville":
			GameLink := this.getHiveLink(UUID, "timv")
			MonthLink := this.getMonthlyLink(UUID, "timv")
			LeadLink := this.getLeadRank(UUID, "timv")
			GameStat := APIRequest(GameLink)
			nextGUI = TIMVStats
		Case "Block Party":
			GameLink := this.getHiveLink(UUID, "bp")
			MonthLink := this.getMonthlyLink(UUID, "bp")
			LeadLink := this.getLeadRank(UUID, "bp")
			GameStat := APIRequest(GameLink)
			nextGUI = BPStats
		}
		return arrInfo := [GameStat, MonthLink, nextGUI]
	}
	
	OnlinePlayers(namesArray, copyrightLine) {			;creates a window with the names given
		Loop % namesArray.maxIndex()				;loops once for each name inside the array
		{
			URL := hiveBase . namesArray[A_Index]		;Add current name from array to the link array[1], array[2] etc.
			allStats := APIRequest(URL) 			;And gather the data for current name.
			Gui, Add, Text,, % "Online status of " . namesArray[A_Index] . ":`n" . allStats.status.description . " " . allStats.status.game ;Add text for current name.
			guiHeight := ((lineHeight * A_Index) + spacing)		;adjust height of the GUI according to how many names there are.
		}
		if (guiHeight >= A_ScreenHeight)
		{
			MsgBox,, % "Hive Statistics GUI v" version " - Error", Window is too big for your screen. Please enter less names., 2
			GoSub, %whereTo%
		} else {
			Gui, Add, Button, x120 w80 gBack Center, Go back 
			Gui, Add, Link, xm y+m, % copyrightLine
			Gui, Show, w370 h%guiHeight% Center
		}
	}
	
	CheckFriendList() {
		if !FileExist(".\resources\friendList.txt")		;checks if there isn't a friend list. 
		{
			fileOK = N
			buttonText = Create friend list
		} else {
			fileOK = Y					;there is, do nothing
			buttonText = Load Friend list
		}
		return fileData := [fileOK, buttonText]
	}
	
	FriendListDo(fileOK, copyrightLine) { 
		if (fileOK == "N")
		{
			this.AddFriendList(copyrightLine)
		} else {
			Gui, Destroy
			FileRead, friendNames, .\resources\friendList.txt
			namesArray := StrSplit(friendNames, ", ")
			this.OnlinePlayers(namesArray, copyrightLine)
		}
	}
	
	AddFriendList(copyrightLine) {
		Gui, Destroy
		Gui, New, +Border, % "Hive Statistics GUI v" version " - Create friend list"
		Gui, Add, Text,, Enter a list of names separated by a comma and a space.
		Gui, Add, Text, yp+20, This will create a file in the resources folder.
		Gui, Add, Edit, x40 w300 h50 vFriendNames -WantReturn
		Gui, Add, Button, xp yp+52 wp Center Default gFriendOK, OK
		Gui, Add, Button, x150 yp+25 w80 Center gBack, Go back
		Gui, Add, Link, xm y+m, % copyrightLine
		Gui, Show, w380 h170
	}
	
	FriendOKPress() {
		Gui, Submit, NoHide
		if (FriendNames == "")
		{
			MsgBox,, % "Hive Statistics GUI v" version " - Error", Invalid string. Enter at least one name., 1.5
			this.AddFriendList()
		} else {
			FileDelete, .\resources\friendList.txt
			FileAppend, %FriendNames%, .\resources\friendList.txt
			MsgBox,, % "Hive Statistics GUI v" version " - Friend list", Friend list created!, 0.7
			Gui, Destroy
			GoSub, OnlinePlayers
		}
	}
	
	getTimezone() {						; Gets user timezone based on system time.
		NowUnix := DateAhkToUnix(A_Now)			; Used to format a player's "last played" time.
		NowUTCUnix := DateAhkToUnix(A_NowUTC)
		return (NowUnix - NowUTCUnix)
	}
}
