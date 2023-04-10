SetWorkingDir %A_ScriptDir%						;ensures a consistent directory.
#Include .\libs\JSON.ahk						;enables commands for data handling.
#Include .\libs\UnixConvert.ahk					;enables commands for time conversion.
#Include .\libs\HiveUtils.ahk					;enables commands for background stuff.
#Include .\libs\DeathRunTimes.ahk				;enables commands for DeathRun times leaderboards.
#NoTrayIcon										;doesn't show the tray icon.
#SingleInstance force							;can only run one instance of the program at a time.
#NoEnv											;doesn't check for empty variables.
Menu, Tray, Icon, .\resources\Logo.ico,, 1		;loads the window icon.

copyrightLine = Made by Nik9094#3814. Press F5 to reload.	;easy access on each window.
global mojangAPI := "https://api.mojang.com/users/profiles/minecraft/"	;Mojang's API link to request for a UUID
global lineHeight = 40 	;Min height to display a single line for online statuses.
global spacing = 60 		;add this height to keep good spacing for the online statuses.
global version = 0.5		;current version to display in the title and other
global FriendNames


APIRequest(URL) {		;initiate connection with specified URL.
	WinHTTP := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	WinHTTP.Open("GET", URL, false)
	WinHTTP.Send()
	return JSON.Load(WinHTTP.ResponseText)		;If everything goes nicely, the whole string of data is saved.
}

timeDiff := Util.getTimezone()		;Get difference in seconds between local timezone and UTC
DRtimeLeads.checkMapsFile()

InitialPage:		;First page the user sees.
	Gui, New, +Border, % "Hive Statistics GUI v" version " - Select action"
	Gui, Add, Text, section, Select what kind of statistics you want to view:
	Gui, Add, Button, xp+20 y30 w150 Center gIGNLabel Default, Player statistics
	Gui, Add, Button, xp+160 yp w150 Center gOnlinePlayers, Player online status
	Gui, Add, Link, xs yp+40, % copyrightLine
	Gui, Show, Center w370 h105
return

IGNLabel:		;Selected to see player stats: must enter a IGN first.
	whereTo = InitialPage
	Gui, Destroy
	Gui, New, +Border, % "Hive Statistics GUI v" version " - Enter name"
	Gui, Add, Text,, Enter the IGN of a player you want to check the stats of: 
	Gui, Add, Edit, w340 Center vIGNBox
	Gui, Add, Button, wp Center Default gIGNok, OK
	Gui, Add, Button, x145 w80 Center gBack, Go back
	Gui, Add, Link, xs, % copyrightLine
	Gui, Show, Center w370 h130
return

IGNok:		;Pressed OK, save name and check for blank names.
	Gui, Submit, NoHide
	IGN = %IGNBox%
	if (IGN == "")
	{
		MsgBox,, % "Hive Statistics GUI v" version " - Error", "Name can't be blank. Please enter a valid name."
	} else {	;Name isn't blank. Go on as normal.
		UUIDget := APIRequest(mojangAPI . IGN)		;get user's UUID from Mojang.
		UUID := UUIDget.id
		Gui, Destroy
		Gosub, GamesPage
	}
return
	
GamesPage:		;Correct name, make new GUI to select a game.
	whereTo = IGNLabel
	Gui, New, +Border, % "Hive Statistics GUI v" version " - " IGN
	Gui, Add, Text,, Select gamemode to show statistics of:
	Gui, Add, DropDownList, vGameSel gSelectedGame Choose1, General|DeathRun|BedWars|SkyWars|Trouble in Mineville|Block Party
	Gui, Add, Button, x135 w80 Center gBack, Go back
	Gui, Add, Link, xm, % copyrightLine
	Gui, Show, Center w350 h100
return

SelectedGame:		;Save selected game, change API link and GUI to show.
	Gui, Submit, NoHide
	GAME = %GameSel%
	Gui, Destroy
	GameInfo := Util.Game(UUID, GAME)	;Retrieves the full JSON string and the next page to show in an array.
	GameStat := GameInfo[1]					;Index 1 of GameInfo has the JSON string of Hive player data.
	MonthLink := GameInfo[2]				;Index 2 has the monthly link.
	nextGUI := GameInfo[3]					;Index 3 has the next page to show.
	GoSub, %nextGUI%
return

GeneralStats:	;Show general stats.
	whereTo = GamesPage
	Gui, New, +Border, % "Hive Statistics GUI v" version " - " IGN
	Gui, Font, underline
	Gui, Add, Text,, Showing general statistics
	Gui, Font, norm
	Gui, Add, Text,, % "Rank: " . GameStat.modernRank.human
	Gui, Add, Text,, % "Tokens: " . GameStat.tokens
	Gui, Add, Text,, % "Medals: " . GameStat.medals
	Gui, Add, Text,, % "Lucky Crates: " . GameStat.crates
	Gui, Add, Text,, % "Status: " . GameStat.status.description . " " . GameStat.status.game
	firstLoginTime := DateUnixToAhk(GameStat.firstLogin + timeDiff, "dd-MM-yyyy HH:mm")
	Gui, Add, Text,, % "First login: " . firstLoginTime . " (local timezone)"
	lastLogoutTime := DateUnixToAhk(GameStat.lastLogout + timeDiff, "dd-MM-yyyy HH:mm")
	Gui, Add, Text,, % "Last logout: " . lastLogoutTime . " (local timezone)"
	Gui, Add, Button, x135 w80 Center gBack, Go back
	Gui, Add, Link, x10 hp, % copyrightLine
	Gui, Show, Center w350 h260
return

DRStats:	;Show DeathRun stats.
	whereTo = GamesPage
	Gui, New, +Border, % "Hive Statistics GUI v" version " - " IGN
	Gui, Font, underline
	Gui, Add, Text,, Showing statistics for DeathRun
	Gui, Font, norm
	Gui, Add, Text,, % "Points: " . GameStat.total_points . " (" . GameStat.title . ")"
	Gui, Add, Text,, % "Games Played: " . GameStat.games_played
	WinR := Format("{:.2f}", ((GameStat.victories / GameStat.games_played) * 100))
	Gui, Add, Text,, % "Victories: " . GameStat.victories . " (Winrate: " . WinR . "%)"
	DPG := Format("{:.2f}", (GameStat.deaths / GameStat.runnergamesplayed))
	Gui, Add, Text,, % "Deaths: " . GameStat.deaths . " (" . DPG . " deaths per game)"
	firstPlayTime := DateUnixToAhk(GameStat.firstlogin + timeDiff, "dd-MM-yyyy HH:mm")
	Gui, Add, Text,, % "First played: " . firstPlayTime . " (local time)"
	Gui, Add, Button, w100 Center gDRtimes, Show map records
	Gui, Add, Button, xp+110 w100 Center gDRMonthly, Show monthly stats
	Gui, Add, Button, x135 w80 gBack Center, Go back
	Gui, Add, Link, x10 hp, % copyrightLine
	Gui, Show, Center w350 h240
return

DRtimes:	;Show DeathRun times.
	whereTo = DRStats
	Gui, Destroy
	Gui, New, +Border, % "Hive Statistics GUI v" version " - " IGN
	Gui, Add, Edit, r10 w170 h200 vDisplayText ReadOnly
	DRtimeLeads.ShowPlayerTimes()
	Gui, Add, Link, x190 y10, Click <a href="https://www.speedrun.com/mcm_hivemc/">here</a> to view the speedrun.com
	Gui, Add, Text, xp yp+15 vCVar, leaderboards.
	GuiControl, Focus, CVar
	Gui, Add, Button, x135 w80 gBack Center, Go back
	Gui, Add, Link, h1 x10, % copyrightLine
	Gui, Show, Center w370 h200
return

DRMonthly:		;Show DeathRun monthly statistics. 
	whereTo = DRStats
	Gui, Destroy
	MonthlyStat := APIRequest(MonthLink)
	Gui, New, +Border, % "Hive Statistics GUI v" version " - " IGN
	Gui, Font, underline
	Gui, Add, Text,, Showing monthly statistics for DeathRun
	Gui, Font, norm
	Gui, Add, Text,, % "Place on leaderboards: " . MonthlyStat.place
	Gui, Add, Text,, % "Points: " . MonthlyStat.points
	Gui, Add, Text,, % "Games played: " . MonthlyStat.played
	WinR := Format("{:.2f}", ((MonthlyStat.victories / MonthlyStat.played) * 100))
	Gui, Add, Text,, % "Wins: " . MonthlyStat.victories . " (Winrate: " . WinR . "%)"
	Gui, Add, Text,, % "Deaths: " . MonthlyStat.deaths
	Gui, Add, Button, x135 w80 gBack Center, Go back
	Gui, Add, Link, h1 x10, % copyrightLine
	Gui, Show, Center w350 h220
return

BEDStats:	;Show BedWars stats.
	whereTo = GamesPage
	Gui, New, +Border, % "Hive Statistics GUI v" version " - " IGN
	Gui, Font, underline
	Gui, Add, Text,, Showing statistics for BedWars
	Gui, Font, norm
	Gui, Add, Text,, % "Points: " . GameStat.total_points . " (" . GameStat.title . ")"
	Gui, Add, Text,, % "Games played: " . GameStat.games_played
	WinR := Format("{:.2f}", ((GameStat.victories / GameStat.games_played) * 100))
	Gui, Add, Text,, % "Wins: " . GameStat.victories . " (Winrate: " . WinR . "%)"
	Gui, Add, Text,, % "Kills: " . GameStat.kills
	KD := Format("{:.2f}", (GameStat.kills / GameStat.deaths))
	Gui, Add, Text,, % "Deaths: " . GameStat.deaths . " (K/D: " . KD . ")"
	Gui, Add, Text,, % "Beds destroyed: " . GameStat.beds_destroyed
	firstPlayTime := DateUnixToAhk(GameStat.firstlogin + timeDiff, "dd-MM-yyyy HH:mm")
	Gui, Add, Text,, % "First played: " . firstPlayTime . " (local time)"
	Gui, Add, Button, Center gBEDMonthly w100, Show montly stats
	Gui, Add, Button, x145 yp w80 gBack Center, Go back
	Gui, Add, Link, h1 x10 yp+40, % copyrightLine
	Gui, Show, Center w370 h270
return

BEDMonthly:
	whereTo = BEDStats
	Gui, Destroy
	MonthlyStat := APIRequest(MonthLink)
	Gui, New, +Border, % "Hive Statistics GUI v" version " - " IGN
	Gui, Font, underline
	Gui, Add, Text,, Showing monthly statistics for BedWars
	Gui, Font, norm
	Gui, Add, Text,, % "Place on leaderboards: " . MonthlyStat.place
	Gui, Add, Text,, % "Points: " . MonthlyStat.points
	Gui, Add, Text,, % "Games played: " . MonthlyStat.played
	WinL := Format("{:.2f}", (MonthlyStat.victories / (MonthlyStat.played - MonthlyStat.victories)))
	Gui, Add, Text,, % "Wins: " . MonthlyStat.victories . " (Win/Loss: " . WinL . ")"
	Gui, Add, Text,, % "Kills: " . MonthlyStat.kills
	KD := Format("{:.2f}", (MonthlyStat.kills / MonthlyStat.deaths))
	Gui, Add, Text,, % "Deaths: " . MonthlyStat.deaths . " (K/D: " . KD . ")"
	Gui, Add, Text,, % "Beds destroyed: " . MonthlyStat.beds
	Gui, Add, Text,, % "Teams eliminated: " . MonthlyStat.teams
	Gui, Add, Button, x135 w80 gBack Center, Go back
	Gui, Add, Link, h1 x10, % copyrightLine
	Gui, Show, Center w350 h300
return

SKYStats:	;Show SkyWars stats.
	whereTo = GamesPage
	Gui, New, +Border, % "Hive Statistics GUI v" version " - " IGN
	Gui, Font, underline
	Gui, Add, Text,, Showing statistics for SkyWars
	Gui, Font, norm
	Gui, Add, Text,, % "Points: " . GameStat.total_points . " (" . GameStat.title . ")"
	Gui, Add, Text,, % "Games played: " . GameStat.gamesplayed
	WinR := Format("{:.2f}", ((GameStat.victories / GameStat.gamesplayed) * 100))
	Gui, Add, Text,, % "Wins: " . GameStat.victories . " (Winrate: " . WinR . "%)"
	Gui, Add, Text,, % "Kills: " . GameStat.kills
	KD  := Format("{:.2f}", (GameStat.kills / GameStat.deaths))
	Gui, Add, Text,, % "Deaths: " . GameStat.deaths . " (K/D: " . KD . ")"
	Gui, Add, Text,, % "Most points gained in one game: " . GameStat.most_points
	SWalive := DateUnixToAhk(GameStat.timealive - 86400, "dd - HH:mm:ss")		;time alive - 1 day
	Gui, Add, Text,, % "Time alive: " . SWalive . " (Days - Hours:Minutes:Seconds)"
	firstPlayTime := DateUnixToAhk(GameStat.firstlogin + timeDiff, "dd-MM-yyyy HH:mm")
	Gui, Add, Text,, % "First played: " . firstPlayTime . " (local time)"
	Gui, Add, Button, w100 gSKYMonthly Center, Show monthly stats
	Gui, Add, Button, x135 yp w80 gBack Center, Go back
	Gui, Add, Link, h1 x10 yp+40, % copyrightLine
	Gui, Show, Center w370 h300
return

SKYMonthly:
	whereTo = SKYStats
	Gui, Destroy
	MonthlyStat := APIRequest(MonthLink)
	Gui, New, +Border, % "Hive Statistics GUI v" version " - " IGN
	Gui, Font, underline
	Gui, Add, Text,, Showing monthly statistics for SkyWars
	Gui, font, norm
	Gui, Add, Text,, % "Place on leaderboards: " . MonthlyStat.place
	Gui, Add, Text,, % "Points: " . MonthlyStat.points
	Gui, Add, Text,, % "Games played: " . MonthlyStat.played
	WinL := Format("{:.2f}", (MonthlyStat.victories / (MonthlyStat.played - MonthlyStat.victories)))
	Gui, Add, Text,, % "Wins: " . MonthlyStat.victories . " (Win/Loss: " . WinL . ")"
	Gui, Add, Text,, % "Kills: " . MonthlyStat.kills
	KD := Format("{:.2f}", (MonthlyStat.kills / MonthlyStat.deaths))
	Gui, Add, Text,, % "Deaths: " . MonthlyStat.deaths . " (K/D: " . KD ")"
	Gui, Add, Button, x135 w80 gBack Center, Go back
	Gui, Add, Link, h1 x10, % copyrightLine
	Gui, Show, Center w350 h250
return

TIMVStats:
	whereTo = GamesPage
	Gui, New, +Border, % "Hive Statistics GUI v" version " - " IGN
	Gui, Font, underline
	Gui, Add, Text,, Showing statistics for Trouble in Mineville
	Gui, Font, norm
	Gui, Add, Text,, % "Karma: " . GameStat.total_points . " (" . GameStat.title . ")"
	Gui, Add, Text,, % "Role points: " . GameStat.role_points . "`nDetective: " . GameStat.d_points . "`nInnocent: " . GameStat.i_points . "`nTraitor: " . GameStat.t_points
	Gui, Add, Text,, % "Max karma gained in one game: " GameStat.most_points
	Gui, Add, Button, w100 gTIMVMonthly Center, Show monthly stats
	Gui, Add, Button, x135 yp w80 gBack Center, Go back
	Gui, Add, Link, h1 x10 yp+40, % copyrightLine
	Gui, Show, Center w350 h210
return

TIMVMonthly:
	whereTo = TIMVStats
	Gui, Destroy
	MonthlyStat := APIRequest(MonthLink)
	Gui, New, +Border, % "Hive Statistics GUI v" version " - " IGN
	Gui, Font, underline
	Gui, Add, Text,, Showing monthly statistics for Trouble in Mineville
	Gui, Font, norm
	Gui, Add, Text,, % "Place on leaderboards: " . MonthlyStat.place
	Gui, Add, Text,, % "Karma: " . MonthlyStat.karma
	RoleP := MonthlyStat.d_points + MonthlyStat.i_points + MonthlyStat.t_points
	Gui, Add, Text,, % "Role points: " . RoleP . "`nDetective: " . MonthlyStat.d_points . "`nInnocent: " . MonthlyStat.i_points . "`nTraitor: " . MonthlyStat.t_points
	Gui, Add, Button, x135 w80 gBack Center, Go back
	Gui, Add, Link, h1 x10, % copyrightLine
	Gui, Show, Center w350 h200
return

BPStats:
	whereTo = GamesPage
	Gui, New, +Border, % "Hive Statistics GUI v" version " - " IGN
	Gui, Font, underline
	Gui, Add, Text,, Showing statistics for Block Party
	Gui, Font, norm
	Gui, Add, Text,, % "Points: " . GameStat.total_points . " (" . GameStat.title . ")"
	WinR := Format("{:.2f}", ((GameStat.victories / GameStat.games_played) * 100))
	Gui, Add, Text,, % "Games played: " . GameStat.games_played " (Winrate: " WinR "%)"
	Gui, Add, Text,, % "Wins: " GameStat.victories
	Gui, Add, Text,, % "Top 3s: " GameStat.total_placing
	Gui, Add, Text,, % "Eliminations: " GameStat.total_eliminations
	firstPlayTime := DateUnixToAhk(GameStat.firstlogin + timeDiff, "dd-MM-yyyy HH:mm")
	Gui, Add, Text,, % "First played: " . firstPlayTime . " (local time)"
	Gui, Add, Button, w100 gBPMonthly Center, Show monthly stats
	Gui, Add, Button, x135 yp w80 gBack Center, Go back
	Gui, Add, Link, h1 x10 yp+40, % copyrightLine
	Gui, Show, Center w350 h250
return

BPMonthly:
	whereTo = BPStats
	Gui, Destroy
	MonthlyStat := APIRequest(MonthLink)
	Gui, New, +Border, % "Hive Statistics GUI v" version " - " IGN
	Gui, Font, underline
	Gui, Add, Text,, Showing monthly statistics for Block Party
	Gui, Font, norm
	Gui, Add, Text,, % "Place on leaderboards: " . MonthlyStat.place
	Gui, Add, Text,, % "Points: " . MonthlyStat.points
	WinR := Format("{:.2f}", ((MonthlyStat.victories / MonthlyStat.played) * 100))
	Gui, Add, Text,, % "Games played: " MonthlyStat.played " (Winrate: " WinR "%)"
	Gui, Add, Text,, % "Wins: " MonthlyStat.victories
	Gui, Add, Text,, % "Top 3s: " MonthlyStat.placings
	Gui, Add, Text,, % "Eliminations: " MonthlyStat.eliminations
	Gui, Add, Button, x135 w80 gBack Center, Go back
	Gui, Add, Link, h1 x10, % copyrightLine
	Gui, Show, Center w350 h240
return

OnlinePlayers:		;Enter names of players for online status.
	whereTo = InitialPage
	fileData := Util.CheckFriendList()			;Run first check if friendList.txt exists
	fileOK := fileData[1]							;file present? save true/false
	buttonText := fileData[2]						;what to show on OnlinePlayers label
	Gui, Destroy
	Gui, New, +Border, % "Hive Statistics GUI v" version " - Enter names"
	Gui, Add, Text,, Enter IGNs of players you want to see the online status of, separate names
	Gui, Add, Text, yp+15, using a comma and a space. Press "Enter" to proceed or click the button.
	Gui, Add, Text, yp+15, This operation takes longer for more names.
	Gui, Add, Edit, w340 h50 vNameInput -WantReturn
	Gui, Add, Button, xp yp+52 wp Center Default gNamesOK, OK
	Gui, Add, Button, x20 yp+25 w100 Center gBack, Go back
	Gui, Add, Button, xp+110 yp w100 Center gLoadFriends, % buttonText
	Gui, Add, Button, xp+110 yp w100 Center gDeleteFriends, Delete friend list
	Gui, Add, Link, xs, % copyrightLine
	Gui, Show, Center w370 h190
return

NamesOK:		;Pressed OK, create GUI for all names.
	whereTo = OnlinePlayers
	Gui, Submit, NoHide
	NameList = %NameInput%
	if (NameList == "")
	{
		MsgBox,, % "Hive Statistics GUI v" version " - Error", Invalid string. Enter at least one name., 1.5
		GoSub, %whereTo%
	} else {
		Gui, Destroy
		Gui, New, +Border, % "Hive Statistics GUI v" version " - Online status"
		namesArray := StrSplit(NameList, ", ")  ;comma+space separates the names.
		Util.OnlinePlayers(namesArray, copyrightLine)	;creates adaptive window to show online statuses.
	}														;I have to call it with copyrightLine because it doesn't hecking work without.
return

LoadFriends:
	whereTo = OnlinePlayers
	Util.FriendListDo(fileOK, copyrightLine)
return

FriendOK:
	Util.FriendOKPress()
return

DeleteFriends:
	if FileExist(".\resources\friendList.txt")
	{
		whereTo = OnlinePlayers
		FileDelete, .\resources\friendList.txt
		MsgBox,, % "Hive Statistics GUI v" version " - Friend list", Friend list deleted!, 0.7
		Util.Back(whereTo)
	} else {
		MsgBox,, % "Hive Statistics GUI v" version " - Friend list", No list to be deleted!, 0.7
	}
return

Back:	;label to call "previous screen" function.
	Util.Back(whereTo)
return

#If WinActive("ahk_exe HivePlayerData.exe") || WinActive("ahk_exe AutoHotKey.exe")	;Reload only works when the program is focused.
F5::Reload
#If
GuiClose:		;Closing any of the windows stops the program.
	ExitApp
return