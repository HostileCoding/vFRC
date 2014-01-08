##################BEGIN FUNCTIONS


function connectServer{

    try {

    $connect = Connect-VIServer -Server $serverTextBox.Text -User $usernameTextBox.Text -Password $passwordTextBox.Text

    $buttonConnect.Enabled = $false #Disable controls once connected
    $serverTextBox.Enabled = $false
    $usernameTextBox.Enabled = $false
    $passwordTextBox.Enabled = $false
    $buttonDisconnect.Enabled = $true #Enable Disconnect button

    getVmHosts #Populate DropDown list with all hosts connected (if vCenter)

    $HostDropDownBox.Enabled=$true
    
    
    $outputTextBox.text = "`nCurrently connected to $($serverTextBox.Text)" #If connection is successfull let user know it

    }

    catch {
    
    $outputTextBox.text = "`nSomething went wrong!!"
    
    }

}

function disconnectServer{

    try {

    $disconnect = Disconnect-VIServer -Confirm:$false -Force:$true

    $buttonConnect.Enabled = $true #Enable login controls once disconnected
    $serverTextBox.Enabled = $true
    $usernameTextBox.Enabled = $true
    $passwordTextBox.Enabled = $true
    $buttonDisconnect.Enabled = $false #Disable Disconnect button
    
    $HostDropDownBox.Items.Clear() #Remove all items from DropDown boxes
    $HostDropDownBox.Enabled=$false #Disable DropDown boxes since they are empty
    $VmDropDownBox.Items.Clear()
    $VmDropDownBox.Enabled=$false
    $HardDiskDropDownBox.Items.Clear()
    $HardDiskDropDownBox.Enabled=$false
    $cacheBlockSizeKBTextBox.Enabled=$false
    $cacheSizeGBTextBox.Enabled=$false
    
    $outputTextBox.text = "`nSuccessfully disconnected from $($serverTextBox.Text)" #If disconnection is successfull let user know it

    }

    catch {
    
    $outputTextBox.text = "`nSomething went wrong!!"
    
    }

}

function getPoweredOffVms{

    try {
    
    $poweredoffvms = Get-VM | Select-Object Name, VMHost, PowerState, Version | Where-Object {$_.PowerState -eq "PoweredOff" -and $_.Version -eq "v10" -and $_.VMHost -eq $(Get-VMHost | Where-Object {$_.Name -eq $HostDropDownBox.SelectedItem.ToString()})} #Returns only powered Off VMs that are hardware v10 (since older hw versions are not supported)

        foreach ($vm in $poweredoffvms) {
            $VmDropDownBox.Items.Add($vm.Name) #Add VMs to DropDown List
        }

    }

    catch {
    
    $outputTextBox.text = "`nSomething went wrong!!"
    
    }


}

function getVmHosts{

    try {

    $vmhosts = Get-VMHost | Where-Object {$_.PowerState -eq "PoweredOn" -and $_.ConnectionState -eq "Connected"} #Returns only powered On VmHosts

        foreach ($vm in $vmhosts) {
            $HostDropDownBox.Items.Add($vm.Name) #Add Hosts to DropDown List
        }    

    }

    catch {
    
    $outputTextBox.text = "`nSomething went wrong getting VMHosts!!"
    
    }

}

function getVmHostvFlashResource{

    try {
    
    $outputTextBox.text = "`nGetting vFRC configuration for VMHost: $($HostDropDownBox.SelectedItem.ToString())"
    
    $vFlashConfig = Get-VMHostVFlashConfiguration -VMHost $HostDropDownBox.SelectedItem.ToString()
    $capacityGbTextBox.text = $($vFlashConfig.CapacityGB)
    $swapCacheGbTextBox.text = $($vFlashConfig.SwapCacheReservationGB)
    $extentsTextBox.text = $($vFlashConfig.Extents)
    
    getPoweredOffVms #Populate DropDown list with all powered off VMs 

    $VmDropDownBox.Enabled=$true

    }

    catch {
    
    $outputTextBox.text = "`nSomething went wrong getting VMHostsvFlashResource!!"
    
    }

}

function getVmvFlashResource{

    try {
    
    $outputTextBox.text = "`nGetting vFRC configuration for VM: $($VmDropDownBox.SelectedItem.ToString())"
    
    $vFlashConfig = Get-HardDiskVFlashConfiguration -HardDisk $(Get-HardDisk -VM $VmDropDownBox.SelectedItem.ToString() -Name $HardDiskDropDownBox.SelectedItem.ToString())
        
    $cacheBlockSizeKBTextBox.text = $vFlashConfig.CacheBlockSizeKB
    
    $cacheSizeGBTextBox.text = $vFlashConfig.CacheSizeGB        
    
    $buttonSetvFrcVm.Enabled = $true #Enable vFRC related button/texbox
    $cacheBlockSizeKBTextBox.Enabled=$true
    $cacheSizeGBTextBox.Enabled=$true
    
    }

    catch {
    
    $outputTextBox.text = "`nSomething went wrong getting VMvFlashResource!!"
    
    }

}

function setVmvFlashResource{
    try{
    
    $cacheSizeGB = $cacheSizeGBTextBox.Text -as [int] #Convert values to integer
    $capacityGb = $capacityGbTextBox.Text -as [int]
    $swapCacheGb = $swapCacheGbTextBox.Text -as [int]
    
    
    if((($cacheBlockSizeKBTextBox.Text -eq 4) -or ($cacheBlockSizeKBTextBox.Text -eq 8) -or ($cacheBlockSizeKBTextBox.Text -eq 16) -or ($cacheBlockSizeKBTextBox.Text -eq 32) -or ($cacheBlockSizeKBTextBox.Text -eq 64) -or ($cacheBlockSizeKBTextBox.Text -eq 128) -or ($cacheBlockSizeKBTextBox.Text -eq 256) -or ($cacheBlockSizeKBTextBox.Text -eq 512) -or ($cacheBlockSizeKBTextBox.Text -eq 1024))){ #Control if CacheBlockSize value is allowed
 
        if($cacheSizeGB -le ($capacityGb - $swapCacheGb)){ #Control if enough resources are available
        
        Set-HardDiskVFlashConfiguration -VFlashConfiguration (Get-HardDiskVFlashConfiguration -HardDisk $(Get-HardDisk -VM $VmDropDownBox.SelectedItem.ToString() -Name $HardDiskDropDownBox.SelectedItem.ToString())) -CacheSizeGB $cacheSizeGBTextBox.Text -CacheBlockSizeKB $cacheBlockSizeKBTextBox.Text -Confirm:$false
        
        getVmvFlashResource #Display updated values
        
        $outputTextBox.text = "`nvFRC correctly set for VM $($VmDropDownBox.SelectedItem.ToString())"
        
        }
        
        else{
        
        $outputTextBox.text = "`nNot enough resources available!!"
        
        }
        
    }
    else{
    
    $outputTextBox.text = "`nvFRC -Block Size in KB- accepted values are: 4, 8, 16, 32, 64, 128, 256, 512, 1024"
    
    }    
    
    }
    catch{
    
    $outputTextBox.text = "`nSomething went wrong setting VMvFlashResource!!"
    
    }
}

function getDisks{

    try {
    
    $HardDiskDropDownBox.Items.Clear() #Remove all items from DropDown List since it may be dirtied by previous executions
    
    $harddisks = Get-HardDisk -VM $VmDropDownBox.SelectedItem.ToString()
    
        foreach ($disk in $harddisks) {
            $HardDiskDropDownBox.Items.Add($disk.Name) #Add Hosts to DropDown List
        }
        
    $HardDiskDropDownBox.Enabled = $true #Enable dropdownbox
        
    }
    catch{
       $outputTextBox.text = "`nSomething went wrong getting VmHardDisks!!"
    }
}

##################END FUNCTIONS

Import-Module VMware.VimAutomation.Extensions #Import VSAN & vFRC cmdlets

[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 

##################Main Form Definition
    
    $main_form = New-Object System.Windows.Forms.Form 
    $main_form.Text = "vFRC GUI" #Form Title
    $main_form.Size = New-Object System.Drawing.Size(500,630) 
    $main_form.StartPosition = "CenterScreen"

    $main_form.KeyPreview = $True
    #$main_form.Add_KeyDown({if ($_.KeyCode -eq "Enter") 
    #{$x=$ServerTextBox.Text;$main_form.Close()}})
    $main_form.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$main_form.Close()}})

##################GroupBox Definition

    $groupBox1 = New-Object System.Windows.Forms.GroupBox
    $groupBox1.Location = New-Object System.Drawing.Size(10,5) 
    $groupBox1.size = New-Object System.Drawing.Size(190,200) #Width, Heigth
    $groupBox1.text = "Connect to vCenter or ESXi host:" 
    $main_form.Controls.Add($groupBox1) 

    $groupBox2 = New-Object System.Windows.Forms.GroupBox
    $groupBox2.Location = New-Object System.Drawing.Size(10,215) 
    $groupBox2.size = New-Object System.Drawing.Size(470,100) #Width, Heigth
    $groupBox2.text = "Hosts Operations:" 
    $main_form.Controls.Add($groupBox2) 

    $groupBox3 = New-Object System.Windows.Forms.GroupBox
    $groupBox3.Location = New-Object System.Drawing.Size(10,325) 
    $groupBox3.size = New-Object System.Drawing.Size(470,100) #Width, Heigth
    $groupBox3.text = "VMs Operations:" 
    $main_form.Controls.Add($groupBox3) 

    $groupBox4 = New-Object System.Windows.Forms.GroupBox
    $groupBox4.Location = New-Object System.Drawing.Size(10,435) 
    $groupBox4.size = New-Object System.Drawing.Size(470,150) #Width, Heigth
    $groupBox4.text = "Output:" 
    $main_form.Controls.Add($groupBox4)
    
    $groupBox5 = New-Object System.Windows.Forms.GroupBox
    $groupBox5.Location = New-Object System.Drawing.Size(210,5) 
    $groupBox5.size = New-Object System.Drawing.Size(270,200) #Width, Heigth
    $groupBox5.text = "Instructions:" 
    $main_form.Controls.Add($groupBox5)  

##################Label Definition

    $Label1 = New-Object System.Windows.Forms.Label
    $Label1.Location = New-Object System.Drawing.Point(10, 20)
    $Label1.Size = New-Object System.Drawing.Size(120, 14)
    $Label1.Text = "IP Address or FQDN:"
    $groupBox1.Controls.Add($Label1) #Member of GroupBox1

    $Label2 = New-Object System.Windows.Forms.Label
    $Label2.Location = New-Object System.Drawing.Point(10, 70)
    $Label2.Size = New-Object System.Drawing.Size(120, 14)
    $Label2.Text = "Username:"
    $groupBox1.Controls.Add($Label2) #Member of GroupBox1

    $Label3 = New-Object System.Windows.Forms.Label
    $Label3.Location = New-Object System.Drawing.Point(10, 120)
    $Label3.Size = New-Object System.Drawing.Size(120, 14)
    $Label3.Text = "Password:"
    $groupBox1.Controls.Add($Label3) #Member of GroupBox1
    
    $Label4 = New-Object System.Windows.Forms.Label
    $Label4.Location = New-Object System.Drawing.Point(10, 15)
    $Label4.Size = New-Object System.Drawing.Size(120, 14)
    $Label4.Text = "Select Host:"
    $groupBox2.Controls.Add($Label4) #Member of GroupBox2
    
    $Label5 = New-Object System.Windows.Forms.Label
    $Label5.Location = New-Object System.Drawing.Point(200, 55)
    $Label5.Size = New-Object System.Drawing.Size(90, 14)
    $Label5.Text = "Capacity in GB:"
    $groupBox2.Controls.Add($Label5) #Member of GroupBox2
    
    $Label6 = New-Object System.Windows.Forms.Label
    $Label6.Location = New-Object System.Drawing.Point(300, 55)
    $Label6.Size = New-Object System.Drawing.Size(160, 14)
    $Label6.Text = "Swap Cache reserved in GB:"
    $groupBox2.Controls.Add($Label6) #Member of GroupBox2
    
    $Label7 = New-Object System.Windows.Forms.Label
    $Label7.Location = New-Object System.Drawing.Point(10, 55)
    $Label7.Size = New-Object System.Drawing.Size(80, 14)
    $Label7.Text = "Extents:"
    $groupBox2.Controls.Add($Label7) #Member of GroupBox2
    
    $Label8 = New-Object System.Windows.Forms.Label
    $Label8.Location = New-Object System.Drawing.Point(10, 15)
    $Label8.Size = New-Object System.Drawing.Size(120, 14)
    $Label8.Text = "Select VM:"
    $groupBox3.Controls.Add($Label8) #Member of GroupBox3
    
    $Label9 = New-Object System.Windows.Forms.Label
    $Label9.Location = New-Object System.Drawing.Point(10, 55)
    $Label9.Size = New-Object System.Drawing.Size(90, 14)
    $Label9.Text = "Block Size in KB:"
    $groupBox3.Controls.Add($Label9) #Member of GroupBox3
    
    $Label10 = New-Object System.Windows.Forms.Label
    $Label10.Location = New-Object System.Drawing.Point(200, 55)
    $Label10.Size = New-Object System.Drawing.Size(160, 14)
    $Label10.Text = "Cache size in GB:"
    $groupBox3.Controls.Add($Label10) #Member of GroupBox3
    
    $Label11 = New-Object System.Windows.Forms.Label
    $Label11.Location = New-Object System.Drawing.Point(200, 15)
    $Label11.Size = New-Object System.Drawing.Size(80, 14)
    $Label11.Text = "Hard Disk:"
    $groupBox3.Controls.Add($Label11) #Member of GroupBox3
    
    $Label12 = New-Object System.Windows.Forms.Label
    $Label12.Location = New-Object System.Drawing.Point(10, 15)
    $Label12.Size = New-Object System.Drawing.Size(250, 180)
    $Label12.Text = "1)Connect to vCenter or ESXi host `r`n`r`n2)Select host and get vFRC configuration `r`n`r`n3)Select VM `r`n`r`n4)Select VM Hard Disk to which enable vFRC `r`n`r`n5)Change -Block Size- and -Cache Size- to desired values `r`n`r`n6)Apply changes pressing -Set vFRC- button `r`n`r`n`Developed by @HostileCoding"
    $groupBox5.Controls.Add($Label12) #Member of GroupBox3

##################Button Definition

    $buttonConnect = New-Object System.Windows.Forms.Button
    $buttonConnect.add_click({connectServer})
    $buttonConnect.Text = "Connect"
    $buttonConnect.Top=170
    $buttonConnect.Left=10
    $groupBox1.Controls.Add($buttonConnect) #Member of GroupBox1

    $buttonDisconnect = New-Object System.Windows.Forms.Button
    $buttonDisconnect.add_click({disconnectServer})
    $buttonDisconnect.Text = "Disconnect"
    $buttonDisconnect.Top=170
    $buttonDisconnect.Left=100
    $buttonDisconnect.Enabled = $false #Disabled by default
    $groupBox1.Controls.Add($buttonDisconnect) #Member of GroupBox1

    $buttonvFrcHost = New-Object System.Windows.Forms.Button
    $buttonvFrcHost.Size = New-Object System.Drawing.Size(260,25) 
    $buttonvFrcHost.add_click({getVmHostvFlashResource})
    $buttonvFrcHost.Text = "Get vFRC configuration for selected Host"
    $buttonvFrcHost.Left=200
    $buttonvFrcHost.Top=25
    $groupBox2.Controls.Add($buttonvFrcHost) #Member of GroupBox2
    
    $buttonGetvFrcVm = New-Object System.Windows.Forms.Button
    $buttonGetvFrcVm.Size = New-Object System.Drawing.Size(125,25) 
    $buttonGetvFrcVm.add_click({getVmvFlashResource})
    $buttonGetvFrcVm.Text = "Get VM vFRC"
    $buttonGetvFrcVm.Left=335
    $buttonGetvFrcVm.Top=25
    $buttonGetvFrcVm.Enabled = $false #Disabled by default
    $groupBox3.Controls.Add($buttonGetvFrcVm) #Member of GroupBox3
    
    $buttonSetvFrcVm = New-Object System.Windows.Forms.Button
    $buttonSetvFrcVm.Size = New-Object System.Drawing.Size(125,25) 
    $buttonSetvFrcVm.add_click({setVmvFlashResource})
    $buttonSetvFrcVm.Text = "Set VM vFRC"
    $buttonSetvFrcVm.Left=335
    $buttonSetvFrcVm.Top=65
    $buttonSetvFrcVm.Enabled = $false #Disabled by default
    $groupBox3.Controls.Add($buttonSetvFrcVm) #Member of GroupBox3

##################TextBox Definition

    $serverTextBox = New-Object System.Windows.Forms.TextBox 
    $serverTextBox.Location = New-Object System.Drawing.Size(10,40) #Left, Top, Right, Bottom
    $serverTextBox.Size = New-Object System.Drawing.Size(165,20) 
    $groupBox1.Controls.Add($serverTextBox) #Member of GroupBox1

    $usernameTextBox = New-Object System.Windows.Forms.TextBox 
    $usernameTextBox.Location = New-Object System.Drawing.Size(10,90)
    $usernameTextBox.Size = New-Object System.Drawing.Size(165,20) 
    $groupBox1.Controls.Add($usernameTextBox) #Member of GroupBox1

    $passwordTextBox = New-Object System.Windows.Forms.MaskedTextBox #Password TextBox
    $passwordTextBox.PasswordChar = '*'
    $passwordTextBox.Location = New-Object System.Drawing.Size(10,140)
    $passwordTextBox.Size = New-Object System.Drawing.Size(165,20)
    $groupBox1.Controls.Add($passwordTextBox) #Member of GroupBox1
    
    $capacityGbTextBox = New-Object System.Windows.Forms.TextBox
    $capacityGbTextBox.Location = New-Object System.Drawing.Size(200,70)
    $capacityGbTextBox.Size = New-Object System.Drawing.Size(90,20)
    $capacityGbTextBox.Enabled=$false 
    $groupBox2.Controls.Add($capacityGbTextBox) #Member of GroupBox2
    
    $swapCacheGbTextBox = New-Object System.Windows.Forms.TextBox
    $swapCacheGbTextBox.Location = New-Object System.Drawing.Size(300,70)
    $swapCacheGbTextBox.Size = New-Object System.Drawing.Size(160,20)
    $swapCacheGbTextBox.Enabled=$false 
    $groupBox2.Controls.Add($swapCacheGbTextBox) #Member of GroupBox2
    
    $extentsTextBox = New-Object System.Windows.Forms.TextBox
    $extentsTextBox.Location = New-Object System.Drawing.Size(10,70)
    $extentsTextBox.Size = New-Object System.Drawing.Size(180,20)
    $extentsTextBox.Enabled=$false 
    $groupBox2.Controls.Add($extentsTextBox) #Member of GroupBox2
    
    $cacheBlockSizeKBTextBox = New-Object System.Windows.Forms.TextBox
    $cacheBlockSizeKBTextBox.Location = New-Object System.Drawing.Size(10,70)
    $cacheBlockSizeKBTextBox.Size = New-Object System.Drawing.Size(90,20)
    $cacheBlockSizeKBTextBox.Enabled=$false 
    $groupBox3.Controls.Add($cacheBlockSizeKBTextBox) #Member of GroupBox3
    
    $cacheSizeGBTextBox = New-Object System.Windows.Forms.TextBox
    $cacheSizeGBTextBox.Location = New-Object System.Drawing.Size(200,70)
    $cacheSizeGBTextBox.Size = New-Object System.Drawing.Size(125,20)
    $cacheSizeGBTextBox.Enabled=$false 
    $groupBox3.Controls.Add($cacheSizeGBTextBox) #Member of GroupBox3

    $outputTextBox = New-Object System.Windows.Forms.TextBox 
    $outputTextBox.Location = New-Object System.Drawing.Size(10,20)
    $outputTextBox.Size = New-Object System.Drawing.Size(450,120)
    $outputTextBox.MultiLine = $True 
    $outputTextBox.ReadOnly = $True
    $outputTextBox.ScrollBars = "Vertical"  
    $groupBox4.Controls.Add($outputTextBox) #Member of groupBox4

##################DropDownBox Definition

    $VmDropDownBox = New-Object System.Windows.Forms.ComboBox
    $VmDropDownBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList #Disable user input in ComboBox
    $VmDropDownBox.Location = New-Object System.Drawing.Size(10,30) 
    $VmDropDownBox.Size = New-Object System.Drawing.Size(180,20) 
    $VmDropDownBox.DropDownHeight = 200
    $VmDropDownBox.Enabled=$false 
    $groupBox3.Controls.Add($VmDropDownBox)
    
    $handler_VmDropDownBox_SelectedIndexChanged={ #DropDownBox SelectedIndexChanged Handler
        try{
            if ($VmDropDownBox.Text.Length -gt 0) {
               getDisks 
            }
        }catch{
        }
    }
    $VmDropDownBox.add_SelectedIndexChanged($handler_VmDropDownBox_SelectedIndexChanged)

    $HostDropDownBox = New-Object System.Windows.Forms.ComboBox
    $HostDropDownBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList #Disable user input in ComboBox
    $HostDropDownBox.Location = New-Object System.Drawing.Size(10,30) 
    $HostDropDownBox.Size = New-Object System.Drawing.Size(180,20) 
    $HostDropDownBox.DropDownHeight = 200
    $HostDropDownBox.Enabled=$false 
    $groupBox2.Controls.Add($HostDropDownBox)
    
    $HardDiskDropDownBox = New-Object System.Windows.Forms.ComboBox
    $HardDiskDropDownBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList #Disable user input in ComboBox
    $HardDiskDropDownBox.Location = New-Object System.Drawing.Size(200,30) 
    $HardDiskDropDownBox.Size = New-Object System.Drawing.Size(125,20) 
    $HardDiskDropDownBox.DropDownHeight = 200
    $HardDiskDropDownBox.Enabled=$false 
    $groupBox3.Controls.Add($HardDiskDropDownBox)
    
    $handler_HardDiskDropDownBox_SelectedIndexChanged={ #DropDownBox SelectedIndexChanged Handler
        try{
            if ($HardDiskDropDownBox.Text.Length -gt 0) {
               $buttonGetvFrcVm.Enabled = $true #Enable button
            }
        }catch{
        }
    }
    $HardDiskDropDownBox.add_SelectedIndexChanged($handler_HardDiskDropDownBox_SelectedIndexChanged)

##################Show Form

    $main_form.Add_Shown({$main_form.Activate()})
    [void] $main_form.ShowDialog()