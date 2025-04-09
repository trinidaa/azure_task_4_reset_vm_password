param(
    [Parameter(Mandatory=$false, ValueFromPipeline=$true)]
    [bool]$DownloadArtifacts=$true
)


# default script values 
$taskName = "task4"

$artifactsConfigPath = "$PWD/artifacts.json"
$resourcesTemplateName = "exported-template.json"
$tempFolderPath = "$PWD/temp"

if ($DownloadArtifacts) { 
    Write-Output "Reading config" 
    $artifactsConfig = Get-Content -Path $artifactsConfigPath | ConvertFrom-Json 

    Write-Output "Checking if temp folder exists"
    if (-not (Test-Path "$tempFolderPath")) { 
        Write-Output "Temp folder does not exist, creating..."
        New-Item -ItemType Directory -Path $tempFolderPath
    }

    Write-Output "Downloading artifacts"

    if (-not $artifactsConfig.resourcesTemplate) { 
        throw "Artifact config value 'resourcesTemplate' is empty! Please make sure that you executed the script 'scripts/generate-artifacts.ps1', and commited your changes"
    } 
    Invoke-WebRequest -Uri $artifactsConfig.resourcesTemplate -OutFile "$tempFolderPath/$resourcesTemplateName" -UseBasicParsing

}

Write-Output "Validating artifacts"
$TemplateFileText = [System.IO.File]::ReadAllText("$tempFolderPath/$resourcesTemplateName")
$TemplateObject = ConvertFrom-Json $TemplateFileText -AsHashtable

$virtualMachine = ( $TemplateObject.resources | Where-Object -Property type -EQ "Microsoft.Compute/virtualMachines" )
if ($virtualMachine) {
    if ($virtualMachine.name.Count -eq 1) { 
        Write-Output "`u{2705} Checked if Virtual Machine exists - OK."
    }  else { 
        Write-Output `u{1F914}
        throw "More than one Virtual Machine resource was found in the VM resource group. Please delete all un-used VMs and try again."
    }
} else {
    Write-Output `u{1F914}
    throw "Unable to find Virtual Machine in the task resource group. Please make sure that you created the Virtual Machine and try again."
}

if ($virtualMachine.location -eq "EastUS" ) {
    Write-Output "`u{2705} Checked Virtual Machine location - OK."
} else { 
    Write-Output `u{1F914}
    throw "Virtual is not deployed to the UK South region. Please re-deploy VM to the UK South region and try again."
}

if (-not $virtualMachine.zones) { 
    Write-Output "`u{2705} Checked Virtual Machine availability zone - OK."
} else {
    Write-Output `u{1F914}
    throw "Virtual machine has availibility zone set. Please re-deploy VM with 'No infrastructure redundancy' availability option and try again." 
}

if (-not $virtualMachine.properties.securityProfile) { 
    Write-Output "`u{2705} Checked Virtual Machine security type settings - OK."
} else { 
    Write-Output `u{1F914}
    throw "Virtual machine security type is set to TMP or Confidential. Please re-deploy VM with security type set to 'Standard' and try again."
}

if ($virtualMachine.properties.storageProfile.imageReference.publisher -eq "canonical") { 
    Write-Output "`u{2705} Checked Virtual Machine OS image publisher - OK" 
} else { 
    Write-Output `u{1F914}
    throw "Virtual Machine uses OS image from unknown published. Please re-deploy the VM using OS image from publisher 'Cannonical' and try again."
}
if ($virtualMachine.properties.storageProfile.imageReference.offer.Contains('ubuntu-server') -and $virtualMachine.properties.storageProfile.imageReference.sku.Contains('22_04')) { 
    Write-Output "`u{2705} Checked Virtual Machine OS image offer - OK"
} else { 
    Write-Output `u{1F914}
    throw "Virtual Machine uses wrong OS image. Please re-deploy VM using Ubuntu Server 22.04 and try again" 
}

if ($virtualMachine.properties.hardwareProfile.vmSize -eq "Standard_B1s") { 
    Write-Output "`u{2705} Checked Virtual Machine size - OK"
} else { 
    Write-Output `u{1F914}
    throw "Virtual Machine size is not set to B1s. Please re-deploy VM with size set to B1s and try again."
}

if ($virtualMachine.properties.osProfile.linuxConfiguration.disablePasswordAuthentication -eq $true) { 
    Write-Output "`u{2705} Checked Virtual Machine OS user authentification settings - OK"
} else { 
    Write-Output `u{1F914}
    throw "Virtual Machine uses password authentification. Please re-deploy VM using SSH key authentification for the OS admin user and try again. "
}


$pip = ( $TemplateObject.resources | Where-Object -Property type -EQ "Microsoft.Network/publicIPAddresses")
if ($pip) {
    if ($pip.name.Count -eq 1) { 
        Write-Output "`u{2705} Checked if the Public IP resource exists - OK"
    }  else { 
        Write-Output `u{1F914}
        throw "More than one Public IP resource was found in the VM resource group. Please delete all un-used Public IP address resources and try again."
    }
} else {
    Write-Output `u{1F914}
    throw "Unable to find Public IP address resouce. Please create a Public IP resouce (Basic SKU, dynamic IP allocation) and try again."
}

if ($pip.properties.dnsSettings.domainNameLabel) { 
    Write-Output "`u{2705} Checked Public IP DNS label - OK"
} else { 
    Write-Output `u{1F914}
    throw "Unable to verify the Public IP DNS label. Please create the DNS label for your public IP and try again."
}


$nic = ( $TemplateObject.resources | Where-Object -Property type -EQ "Microsoft.Network/networkInterfaces")
if ($nic) {
    if ($nic.name.Count -eq 1) { 
        Write-Output "`u{2705} Checked if the Network Interface resource exists - OK"
    }  else { 
        Write-Output `u{1F914}
        throw "More than one Network Interface resource was found in the VM resource group. Please delete all un-used Network Interface resources and try again."
    }
} else {
    Write-Output `u{1F914}
    throw "Unable to find Network Interface resouce. Please re-deploy the VM and try again."
}

if ($nic.properties.ipConfigurations.Count -eq 1) { 
    if ($nic.properties.ipConfigurations.properties.publicIPAddress -and $nic.properties.ipConfigurations.properties.publicIPAddress.id) { 
        Write-Output "`u{2705} Checked if Public IP assigned to the VM - OK"
    } else { 
        Write-Output `u{1F914}
        throw "Unable to verify Public IP configuratio for the VM. Please make sure that IP configuration of the VM network interface has public IP address configured and try again."
    }
} else {
    Write-Output `u{1F914}
    throw "Unable to verify IP configuration of the Network Interface. Please make sure that you have 1 IP configuration of the VM network interface and try again."
}


$nsg = ( $TemplateObject.resources | Where-Object -Property type -EQ "Microsoft.Network/networkSecurityGroups")
if ($nsg) {
    if ($nsg.name.Count -eq 1) { 
        Write-Output "`u{2705} Checked if the Network Security Group resource exists - OK"
    }  else { 
        Write-Output `u{1F914}
        throw "More than one Network Security Group resource was found in the VM resource group. Please delete all un-used Network Security Group resources and try again."
    }
} else {
    Write-Output `u{1F914}
    throw "Unable to find Network Security Group resouce. Please re-deploy the VM and try again."
}

$sshNsgRule = ( $nsg.properties.securityRules | Where-Object { ($_.properties.destinationPortRange -eq '22') -and ($_.properties.access -eq 'Allow')} ) 
if ($sshNsgRule)  {
    Write-Output "`u{2705} Checked if NSG has SSH network security rule configured - OK"
} else { 
    Write-Output `u{1F914}
    throw "Unable to fing network security group rule which allows SSH connection. Please check if you configured VM Network Security Group to allow connections on 22 TCP port and try again."
}

$httpNsgRule = ( $nsg.properties.securityRules | Where-Object { ($_.properties.destinationPortRange -eq '8080') -and ($_.properties.access -eq 'Allow')} ) 
if ($httpNsgRule)  {
    Write-Output "`u{2705} Checked if NSG has HTTP network security rule configured - OK"
} else { 
    Write-Output `u{1F914}
    throw "Unable to fing network security group rule which allows HTTP connection. Please check if you configured VM Network Security Group to allow connections on 8080 TCP port and try again."
}

$passwordResetExtention = ( $TemplateObject.resources | Where-Object {($_.type -eq "Microsoft.Compute/virtualMachines/extensions") -and ($_.properties.type -eq "VMAccessForLinux") } ) 
if ($passwordResetExtention) {
    Write-Output "`u{2705} Checked if VM admin password was reset - OK"
} else {
    Write-Output `u{1F914}
    throw "Unable to verify that VM admin password was ever reset on the virtual machine. Please reset VM admin password and try again. "
}

Write-Output ""
Write-Output "`u{1F973} Congratulations! All tests passed!"
