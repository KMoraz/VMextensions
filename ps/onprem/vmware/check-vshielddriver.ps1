 #Define Table Array
 $vmtable = @()
 
 $vmlist | % {
  $windowspath = "Inaccessible";
  $vsenotpresent = "Unknown";
 $windowspath = (test-path "\\$($_.vmname)\c$\windows\");
  $vsenotpresent = (!(test-path "\\$($_.vmname)\c$\windows\system32\drivers\vsepflt.sys"))

 # Typically place this into a loop:
 $vmline = New-Object -TypeName PSObject -Property `
                @{
                "VMName" = "$($_.vmname)";
                "Accessible" = $windowspath;
                "VSe not present" = $vsenotpresent
                }
        write-host $vmline
$vmtable += $vmline
}
