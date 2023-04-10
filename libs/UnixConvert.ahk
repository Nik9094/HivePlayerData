;MsgBox, % vNum := DateAhkToUnix(vDate)					;placeholder for debug: CurrentTime -> Unix
;MsgBox, % DateUnixToAhk(vNum, "dd-MM-yyyy HH:mm:ss")	;placeholder for debug: Unix -> CurrentTime

;number of seconds elapsed since 00:00:00 UTC, Thursday, 1 January 1970, minus the number of leap seconds that have taken place since then

DateUnixToAhk(vNum:="", vFormat:="ddMMyyyyHHmmss") {	;call function in main with unix on vNum and preferred format 
	if !(vNum = "")
		vDate := DateAdd(1970, vNum, "Seconds")
	if (vNum = "") || !(vFormat == "ddMMyyyyHHmmss")
		return FormatTime(vDate, vFormat)
	return vDate
}

;==================================================
;Current time to Unix.
;vDate: blank value means now
DateAhkToUnix(vDate:="") {
	return DateDiff(vDate, 1970, "Seconds")
}

;==================================================

DateAdd(DateTime, Time, TimeUnits) {
    EnvAdd DateTime, %Time%, %TimeUnits% 
    return DateTime
}

DateDiff(DateTime1, DateTime2, TimeUnits) {
    EnvSub DateTime1, %DateTime2%, %TimeUnits%
    return DateTime1
}

FormatTime(DDMMYYYYHH24MISS:="", Format:="") {
    local OutputVar
    FormatTime OutputVar, %DDMMYYYYHH24MISS%, %Format%
    return OutputVar
}