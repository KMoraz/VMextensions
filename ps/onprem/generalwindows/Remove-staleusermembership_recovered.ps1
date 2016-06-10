# Remove-staleusermembership.ps1
# William Ayerst / Capita 12.2015

# Cleanse variables from previous runs
clear-variable userreport 
clear-variable userstatus
clear-variable userline
clear-variable staleusermembershipoutfile
clear-variable group
clear-variable gname
clear-variable uname
clear-variable searchou

# Set outfile
$staleusermembershipoutfile = "c:\Scripts\StaleUsersMembership_$((Get-Date).ToString('dd-MM-yyyy')).csv" `
# Test path for outfile, create it if absent
if(!(Test-Path -Path $staleusermembershipoutfile))
 {
  new-item -Path $staleusermembershipoutfile –itemtype file -force
 }


# Get AD groups that are Security or Distribution in an OU
# Define the OU 
$searchOU = "OU=Groups,OU=Basingstoke,DC=adcfs,dc=capita,dc=co,dc=uk"
# Query the OU
Get-ADGroup -Filter 'GroupCategory -eq "Security" -or GroupCategory -eq "Distribution"' -SearchBase $searchOU |`

# Specific Group Query Below
# Get-ADGroup -identity "Test_Permissions_Replication" |`


# Loop for each group in the OU 
 ForEach-Object { $group = $_
                # Get the group membership
                Get-ADGroupMember -Identity $group -Recursive |`
                # For each member, get the enable/disable status
                ForEach-Object { Get-ADUser -Identity $_.distinguishedName -Properties Enabled,lastlogondate |`
                    # Filter those disabled
                    ?{$_.Enabled -eq $false}} |` 
                    # For each disabled user, remove them from the group
                    ForEach-Object{ $user = $_
                           $gname = $group.Name		                
                           $uname = $user.Name
		                   $ldate = $user.lastlogondate
                        # Create an array for the status of each stale user
                        $userstatus = @{ "Disabled User" = $uname;
                                     "Group"= $gname;
                                     "Last User Logon date" = $ldate}
                        # Create single line object for the stale user array
                        New-Object -TypeName PSObject -Property $userstatus -OutVariable userline | out-null
                        # Add the line object to a report variable
                        $userreport += $userline

                        #
                        # Remove commented lines to give automated action
                        #
                        #
                        # Write shell info about user being removed
                        # Write-Host "Removing $uname from $gname" -Foreground Yellow                                                
                        # Remove member		                
                        # Remove-ADGroupMember -Identity $group -Member $user -Confirm:$false
                               }
                }

# Output the full report variable after looping to CSV
$userreport | Export-Csv $staleusermembershipoutfile -NoTypeInformation -append
invoke-item $staleusermembershipoutfile

