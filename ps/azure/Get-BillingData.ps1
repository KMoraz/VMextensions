Param(
   [string]$EnrollmentNbr = "9075954",
   [string]$Key = "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6IlE5WVpaUnA1UVRpMGVPMmNoV19aYmh1QlBpWSJ9.eyJFbnJvbGxtZW50TnVtYmVyIjoiOTA3NTk1NCIsIklkIjoiOWI5ZTcxYmItOWUxNi00MDUwLTk2MWYtMjlmNTI3MzBkN2E3IiwiUmVwb3J0VmlldyI6IkVudGVycHJpc2UiLCJQYXJ0bmVySWQiOiIiLCJEZXBhcnRtZW50SWQiOiIiLCJBY2NvdW50SWQiOiIiLCJpc3MiOiJlYS5taWNyb3NvZnRhenVyZS5jb20iLCJhdWQiOiJjbGllbnQuZWEubWljcm9zb2Z0YXp1cmUuY29tIiwiZXhwIjoxNDc1ODM5NzUxLCJuYmYiOjE0NjAwMjg1NTF9.bbMN8Qa7scgvB0JCD7WQOPbt_VFCn7fswuxLa7GOAlzh5vMspvwt_BakNpcC18tvJ3yPY5lhXnmKOyMPLkFITIoVLuqHNj5GMi5WP7_xwldIcNf-EmLltFHYAay6_mmR0aK0fg4tS40MqXF8BwQIq6659gdWX-WbGcvAARkiPZk3Iw2HJza1FyUaOZL_B8YfgtLLaeid6TaQc-VmK7JUXxaFs-mr733OhtWISLcJ1oPEH6ie39Hp55DZ1P3h4LhgO6oDL8qmZKDcmXIX963L3x-pP_xmkKNo5-kxsLTUfOmp2_lEU3q1hmEX1f85-NCiSMF0a5J2u3S8LJjTi1xP9Q",
   [string]$Month = "2016-04"
)
# access token is "bearer " and the the long string of garbage
$AccessToken = "Bearer $Key"
$urlbase = 'https://ea.azure.com'
$csvAll = @()

Write-Verbose "$(Get-Date -format 's'): Azure Enrollment $EnrollmentNbr"

# function to invoke the api, download the data, import it, and merge it to the global array
Function DownloadUsageReport( [string]$LinkToDownloadDetailReport, $csvAll )
{
		Write-Verbose "$(Get-Date -format 's'): $urlbase/$LinkToDownloadDetailReport)"
		$webClient = New-Object System.Net.WebClient
		$webClient.Headers.add('api-version','1.0')
		$webClient.Headers.add('Authorization', "$AccessToken")
		$data = $webClient.DownloadString("$urlbase/$LinkToDownloadDetailReport")
		# remove the funky stuff in the leading rows - skip to the first header column value
		$pos = $data.IndexOf("AccountOwnerId")
		$data = $data.Substring($pos-1)
		# convert from CSV into an ps variable
		$csvM = ($data | ConvertFrom-CSV)
		# merge with previous
		$csvAll = $csvAll + $csvM
		Write-Verbose "Rows = $($csvM.length)"
		return $csvAll
}

if ( $Month -eq "" )
{
	# if no month specified, invoke the API to get all available months
	Write-Verbose "$(Get-Date -format 's'): Downloading available months list"
	$webClient = New-Object System.Net.WebClient
	$webClient.Headers.add('api-version','1.0')
	$webClient.Headers.add('Authorization', "$AccessToken")
	$months = ($webClient.DownloadString("$urlbase/rest/$EnrollmentNbr/usage-reports") | ConvertFrom-Json)

	# loop through the available months and download data. 
	# List is sorted in most recent month first, so start at end to get oldest month first 
	# and avoid sorting in Excel
	for ($i=$months.AvailableMonths.length-1; $i -ge 0; $i--) {
		$csvAll = DownloadUsageReport $($months.AvailableMonths.LinkToDownloadDetailReport[$i]) $csvAll
	}
}
else
{
	# Month was specified as a parameter, so go ahead and just download that month
	$csvAll = DownloadUsageReport "rest/$EnrollmentNbr/usage-report?month=$Month&type=detail" $csvAll
}
Write-Host "Total Rows = $($csvAll.length)"

# data is in US format wrt Date (MM/DD/YYYY) and decimal values (3.14)
# so loop through and convert columns to local format so that Excel can be happy
Write-verbose "$(Get-Date -format 's'): Fixing datatypes..."
for ($i=0; $i -lt $csvAll.length; $i++) {
	$csvAll[$i].Date = [datetime]::ParseExact( $csvAll[$i].Date, 'dd/mm/yyyy', $null).ToString("d")
	$csvAll[$i].ExtendedCost = [float]$csvAll[$i].ExtendedCost
	$csvAll[$i].ResourceRate = [float]$csvAll[$i].ResourceRate
	$csvAll[$i].'Consumed Quantity' = [float]$csvAll[$i].'Consumed Quantity'

    # Expand tags
    $tags = $csvAll[$i].Tags | ConvertFrom-Json
    if ($tags -ne $null) {
         $tags.psobject.properties | ForEach { 
            $tagName = "Tag-$($_.Name)" 
            Add-Member -InputObject $csvAll[$i] $tagName $_.Value 
            # Add to first row, as that's what is used to format the CSV
            if ($csvAll[0].psobject.Properties[$tagName] -eq $null) {
                Add-Member -InputObject $csvAll[0] $tagName $null -Force
            }
        }
    }

}

# save the data to a CSV file
$filename = ".\$($EnrollmentNbr)_UsageDetail$($Month)_$(Get-Date -format 'yyyyMMdd').csv"
Write-Host "$(Get-Date -format 's'): Saving to file $filename"
$csvAll | Export-Csv $filename -NoTypeInformation -Delimiter ","