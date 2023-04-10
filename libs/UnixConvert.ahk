/* A slightly edited library for converting UNIX timestamp to a readable format.
 * Not made by me, but edited by me. I unfortunately cannot find the original.
*/


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
