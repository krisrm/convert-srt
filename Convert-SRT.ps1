[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)]
  [String]$file,
  [String]$timeOffset
)

$timeOffsetTs = [Timespan]::Parse($timeOffset) #Note: this needs to be in a format that Timespan::Parse can handle.

#Expecting a file with this format:
#469
#00:00:10,000 --> 00:00:09,000
#00:17:25:28 The actual caption text 

#Annotated:
#111 (caption number)
#00:00:10,000 --> 00:00:09,000 (nonsense timestamps)
#00:17:25:28 (start timestamp of the actual caption) The actual caption text

#Producing:
#111
#00:17:25,028 --> 00:17:26,054
#The actual caption text

$srtIn = Get-Content $file
$srtOut = ""
$txtOut = ""
$fileNoExtension = [io.path]::GetFileNameWithoutExtension($file)
$srtOutFile = "$fileNoExtension.converted.srt"
$txtOutFile = "$fileNoExtension.converted.txt"
$captionNum = 0
$lastTimestamp = [Timespan]::Parse("00:00:00") + $timeOffsetTs
$lastTimestampMs = "00"
$thisTimestamp = [Timespan]::Parse("00:00:00") + $timeOffsetTs
$thisTimestampMs = "00"


Write-Host "Parsing .srt file at: $file and saving as $srtOutFile"
if ($timeOffset) {
    Write-Host "Adding time offset of $timeOffsetTs to timestamps in the .srt file"
}

foreach ($line in $srtIn) {
	if ($line -match "^\d+$") {
		$captionNum = $line;
		#Write-Host $line
	} 
	$captionNumMatch = [regex]::Match($line, "(\d\d:\d\d:\d\d):(\d\d)\s(.*)")
	if ($captionNumMatch.Success) {
		$lastTimestamp = $thisTimestamp
        $lastTimestampMs = $thisTimestampMs
		$thisTimestamp = [Timespan]::Parse($captionNumMatch.captures.groups[1].value) + $timeOffsetTs

        $thisTimestampMs = $captionNumMatch.captures.groups[2].value
		
		$captionValue = $captionNumMatch.captures.groups[3].value
	}
	if ($line -eq "") {
		$srtOut += "$captionNum`n"
		$srtOut += "$lastTimestamp,0$lastTimestampMs --> $thisTimestamp,0$thisTimestampMs`n"
		$srtOut += "$captionValue`n"
		$srtOut += "`n"
		$txtOut += "$captionValue`n"
	}
}

Set-Content -Path $srtOutFile -Value $srtOut
Set-Content -Path $txtOutFile -Value $txtOut

Write-Host "Completed, check $srtOutFile"