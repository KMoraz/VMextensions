# _____________________ #
#                       #
# ___ LOG FUNCTION ____ #
# _____________________ #
#
# This is our logging function, it must appear above the code where you are trying to use it.

# Define a new log name
$logfile = "c:\scripts\logs\$(get-date -Format yymmddhhmm).log"

function log($string, $color)
{
   if ($Color -eq $null) {$color = "white"}
   write-host $string -foregroundcolor $color
   $string | out-file -Filepath $logfile -append
}