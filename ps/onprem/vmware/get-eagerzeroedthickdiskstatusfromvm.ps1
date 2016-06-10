$vm = Get-VM cfsnthfp01
$vm.ExtensionData.Config.Hardware.Device | 
where {$_ -is [VMware.Vim.VirtualDisk]} | 
Select @{N="VM";E={$vm.Name}},
@{N="HD";E={$_.DeviceInfo.Label}},
@{N="EagerlyScrub";E={$_.Backing.EagerlyScrub}},
@{N="Type";E={$_.Backing.GetType().Name}},
@{N="ThinProvisioned";E={$_.Backing.ThinProvisioned}}