##get-vm -location "beckenham" | where-object {$_.powerstate -eq "poweredon"} | where-object {$_.name -like "uat*" -or $_.name -like "dev*" -or $_.name -like "sit*" -or $_.name -like "tst*"} | Shutdown-VMGuest -confirm:$false

clear-host
# fdjiofjdsop
$count = 1000

do {$count  = (get-vm -location "beckenham" | where-object {$_.powerstate -eq "poweredon"}).count;
		write-host "$(get-date) - $count servers remaining"}
while ($count -gt 1)


