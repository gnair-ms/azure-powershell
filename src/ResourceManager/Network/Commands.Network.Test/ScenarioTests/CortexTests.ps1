﻿# ----------------------------------------------------------------------------------
#
# Copyright Microsoft Corporation
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ----------------------------------------------------------------------------------

<#
.SYNOPSIS
Virtual network express route gateway tests
#>
function Test-CortexCRUD
{
 # Setup
    $rgname = Get-ResourceGroupName
    $rname = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $vnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $vnetGatewayConfigName = Get-ResourceName
    $rglocation = "centraluseuap"

	$virtualWanName = Get-ResourceName
	$virtualHubName = Get-ResourceName
	$vpnSiteName = Get-ResourceName
	$vpnGatewayName = Get-ResourceName
	$remoteVirtualNetworkName = Get-ResourceName
	$vpnConnectionName = Get-ResourceName
	$hubVnetConnectionName = Get-ResourceName
    
	try
	{
		# Create the resource group
        $resourceGroup = New-AzureRmResourceGroup -Name $rgname -Location $rglocation

		# Create the Virtual Wan
		$createdVirtualWan = New-AzureRmVirtualWan -ResourceGroupName $rgName -Name $virtualWanName -Location $rglocation
		$virtualWan = Get-AzureRmVirtualWan -ResourceGroupName $rgName -Name $virtualWanName
		Assert-AreEqual $createdVirtualWan.ResourceGroupName $virtualWan.ResourceGroupName
		Assert-AreEqual $createdVirtualWan.Name $virtualWan.Name

		# Create the Virtual Hub
		$createdVirtualHub = New-AzureRmVirtualHub -ResourceGroupName $rgName -Name $virtualHubName -Location $rglocation -AddressPrefix "192.168.1.0/24" -VirtualWan $virtualWan
		$virtualHub = Get-AzureRmVirtualHub -ResourceGroupName $rgName -Name $virtualHubName
		Assert-AreEqual $createdVirtualHub.ResourceGroupName $virtualHub.ResourceGroupName
		Assert-AreEqual $createdVirtualHub.Name $virtualHub.Name

		# Create the VpnSite
		$vpnSiteAddressSpaces = New-Object string[] 2
		$vpnSiteAddressSpaces[0] = "192.168.2.0/24"
		$vpnSiteAddressSpaces[1] = "192.168.3.0/24"
		$createdVpnSite = New-AzureRmVpnSite -ResourceGroupName $rgName -Name $vpnSiteName -Location $rglocation -VirtualWan $virtualWan -IpAddress "1.2.3.4" -AddressSpace $vpnSiteAddressSpaces -DeviceModel "SomeDevice" -DeviceVendor "SomeDeviceVendor" -LinkSpeedInMbps "10"
		$vpnSite = Get-AzureRmVpnSite -ResourceGroupName $rgname -Name $vpnSiteName
		Assert.AreEqual $createdVpnSite.ResourceGroupName $vpnSite.ResourceGroupName
		Assert.AreEqual $createdVpnSite.Name $vpnSite.Name

		# Create the VpnGateway
		$createdVpnGateway = New-AzureRmVpnGateway -ResourceGroupName $rgName -Name $vpnGatewayName -VirtualHub $virtualHub -VpnGatewayScaleUnit 1
		$vpnGateway = Get-AzureRmVpnGateway -ResourceGroupName $rgName -Name $vpnGatewayName
		Assert.AreEqual $createdVpnGateway.ResourceGroupName $vpnGateway.ResourceGroupName
		Assert.AreEqual $createdVpnGateway.Name $vpnGateway.Name

		# Create the VpnConnection
		$createdVpnConnection = New-AzureRmVpnConnection -ResourceGroupName $vpnGateway.ResourceGroupName -ParentResourceName $vpnGateway.Name -Name $vpnConnectionName -VpnSite $vpnSite -ConnectionBandwidth 20
		$vpnConnection = Get-AzureRmVpnConnection -ResourceGroupName $vpnGateway.ResourceGroupName -ParentResourceName $vpnGateway.Name -Name $vpnConnectionName
		Assert.AreEqual $createdVpnConnection.ResourceGroupName $vpnConnection.ResourceGroupName
		Assert.AreEqual $createdVpnConnection.Name $vpnConnection.Name

		# Create a HubVirtualNetworkConnection
		$createdHubVnetConnection = New-AzureRmHubVirtualNetworkConnection -ResourceGroupName $rgName -VirtualHubName $virtualHub.Name -Name $hubVnetConnectionName -RemoteVirtualNetwork $remoteVirtualNetwork
		$hubVnetConnection = Get-AzureRmHubVirtualNetworkConnection -ResourceGroupName $rgName -VirtualHubName $virtualHub.Name -Name $hubVnetConnectionName
	}
	finally
	{
		Remove-AzureRmHubVirtualNetworkConnection -ResourceGroupName $rgName -VirtualHubName $virtualHubName -Name $hubVnetConnectionName
		Remove-AzureRmVpnConnection -ResourceGroupName $rgName -ParentResourceName $vpnGatewayName -Name $vpnConnectionName
		Remove-AzureRmVpnGateway -ResourceGroupName $rgname -Name $vpnGatewayName
		Remove-AzureRmVpnSite -ResourceGroupName $rgname -Name $vpnSiteName
		Remove-AzureRmVirtualHub -ResourceGroupName $rgname -Name $virtualHubName
		Remove-AzureRmVirtualWan -ResourceGroupName $rgName -Name $virtualWanName
	}
}


<# .SYNOPSIS
 Point to site Cortex feature tests
 #>
 function Test-P2SCortexCRUD
 {
    # Setup
    $rgname = Get-ResourceGroupName
    $rglocation = Get-ProviderLocation ResourceManagement
 
    $virtualWanName = Get-ResourceName
    $virtualHubName = Get-ResourceName
    $p2sVpnServerConfiguration1Name = Get-ResourceName
    $p2sVpnServerConfiguration2Name = Get-ResourceName
    $p2sVpnGatewayName = Get-ResourceName
    $vpnclientAuthMethod = "EAPTLS"
 
    try
    {
        # Create the resource group
        $resourceGroup = New-AzureRmResourceGroup -Name $rgname -Location $rglocation
 
        # Create the Virtual Wan
        $createdVirtualWan = New-AzureRmVirtualWan -ResourceGroupName $rgName -Name $virtualWanName -Location $rglocation
        $virtualWan = Get-AzureRmVirtualWan -ResourceGroupName $rgName -Name $virtualWanName
        Assert-AreEqual $createdVirtualWan.ResourceGroupName $virtualWan.ResourceGroupName
        Assert-AreEqual $createdVirtualWan.Name $virtualWan.Name
 
        # Create the Virtual Hub
        $createdVirtualHub = New-AzureRmVirtualHub -ResourceGroupName $rgName -Name $virtualHubName -Location $rglocation -AddressPrefix "192.168.1.0/24" -VirtualWan $virtualWan
        $virtualHub = Get-AzureRmVirtualHub -ResourceGroupName $rgName -Name $virtualHubName
        Assert-AreEqual $createdVirtualHub.ResourceGroupName $virtualHub.ResourceGroupName
        Assert-AreEqual $createdVirtualHub.Name $virtualHub.Name
 
        # Create the P2SVpnServerConfiguration1 with VpnClient settings and associate it with Virtual wan using Set-AzureRmVirtualWan
        $p2sVpnServerConfigCertFilePath = $basedir + "\ScenarioTests\Data\ApplicationGatewayAuthCert.cer"
        $listOfCerts = New-Object "System.Collections.Generic.List[String]"
        $listOfCerts.Add($p2sVpnServerConfigCertFilePath)
        $vpnclientipsecpolicy1 = New-AzureRmVpnClientIpsecPolicy -IpsecEncryption AES256 -IpsecIntegrity SHA256 -SALifeTime 86471 -SADataSize 429496 -IkeEncryption AES256 -IkeIntegrity SHA384 -DhGroup DHGroup2 -PfsGroup PFS2
        $p2sVpnServerConfigObject1 = New-AzureRmP2SVpnServerConfigurationObject -Name $p2sVpnServerConfiguration1Name -VpnProtocol IkeV2 -P2SVpnServerConfigVpnClientRootCertificateFilesList $listOfCerts -P2SVpnServerConfigVpnClientRevokedCertificateFilesList $listOfCerts -VpnClientIpsecPolicy $vpnclientipsecpolicy1
 
        Set-AzureRmVirtualWan -Name $virtualWanName -ResourceGroupName $rgName -P2SVpnServerConfiguration $p2sVpnServerConfigObject1
        # Set-AzureRmVirtualWan -VirtualWan
        # Set-AzureRmVirtualWan -VirtualWanId
 
        $virtualWan = Get-AzureRmVirtualWan -ResourceGroupName $rgName -Name $virtualWanName
        Assert-AreEqual $createdVirtualWan.ResourceGroupName $virtualWan.ResourceGroupName
        Assert-AreEqual $createdVirtualWan.Name $virtualWan.Name
        Assert-AreEqual 1 $createdVirtualWan.Name $virtualWan.P2SVpnServerConfigurations.Count
        Assert-AreEqual $p2sVpnServerConfiguration1Name $createdVirtualWan.Name $virtualWan.P2SVpnServerConfigurations[0].Name
 
        # Get created P2SVpnServerConfiguration using Get-AzureRmVirtualWanP2SVpnServerConfiguration
        $p2sVpnServerConfig1 = Get-AzureRmVirtualWanP2SVpnServerConfiguration -VirtualWanName $virtualWanName -ResourceGroupName $rgName -Name $p2sVpnServerConfiguration1Name
		Assert-AreEqual $p2sVpnServerConfiguration1Name $p2sVpnServerConfig1.Name
        $protocols = $p2sVpnServerConfig1.VpnProtocols
        Assert-AreEqual 1 @($protocols).Count
        Assert-AreEqual "IkeV2" $protocols[0]
 
        # Create the P2SVpnGateway
        $vpnClientAddressSpaces = New-Object string[] 2
        $vpnClientAddressSpaces[0] = "192.168.2.0/24"
        $vpnClientAddressSpaces[1] = "192.168.3.0/24"
        $createdP2SVpnGateway = New-AzureRmP2SVpnGateway -ResourceGroupName $rgName -Name $P2SvpnGatewayName -VirtualHub $virtualHub -VpnGatewayScaleUnit 1 -VpnClientAddressPool $vpnClientAddressSpaces -P2SVpnServerConfiguration $p2sVpnServerConfig1
        Assert.AreEqual $p2sVpnServerConfig1.Name $createdP2SVpnGateway.P2SVpnServerConfiguration.Name
 
        # Get the created P2SVpnGateway using Get-AzureRmP2SVpnGateway
        $P2SvpnGateway = Get-AzureRmP2SVpnGateway -ResourceGroupName $rgName -Name $P2SvpnGatewayName
        Assert.AreEqual $createdP2SVpnGateway.ResourceGroupName $P2SvpnGateway.ResourceGroupName
        Assert.AreEqual $createdP2SVpnGateway.Name $P2SvpnGateway.Name
        Assert.AreEqual $createdP2SVpnGateway.Name $P2SvpnGateway.P2SVpnServerConfiguration.Name
 
        # Generate vpn profile using Get-AzureRmP2SVpnGatewayVpnProfile
        $vpnProfileResponse = Get-AzureRmP2SVpnGatewayVpnProfile -Name $p2sVpnGatewayName -ResourceGroupName $rgName -AuthenticationMethod $vpnclientAuthMethod
        Write-Host $vpnProfilePackageUrl.ProfileUrl
 
        # Create the P2SVpnServerConfiguration2 with RadiusClient settings and associate it with the Virtual wan using New-AzureRmVirtualWanP2SVpnServerConfiguration
        $Secure_String_Pwd = ConvertTo-SecureString "TestRadiusServerPassword" -AsPlainText -Force
        $p2sVpnServerConfigObject2 = New-AzureRmP2SVpnServerConfigurationObject -Name $p2sVpnServerConfiguration2Name -VpnProtocol IkeV2 -RadiusServerAddress "TestRadiusServer" -RadiusServerSecret $Secure_String_Pwd -P2SVpnServerConfigRadiusServerRootCertificateFilesList $listOfCerts -P2SVpnServerConfigRadiusClientRootCertificateFilesList $listOfCerts
        $createdP2SVpnServerConfig2 = New-AzureRmVirtualWanP2SVpnServerConfiguration -Name $p2sVpnServerConfiguration2Name -ResourceGroupName $rgName -VirtualWanName $virtualWanName -P2SVpnServerConfiguration $p2sVpnServerConfigObject2
 
        $virtualWan = Get-AzureRmVirtualWan -ResourceGroupName $rgName -Name $virtualWanName
        Assert-AreEqual 2 $createdVirtualWan.Name $virtualWan.P2SVpnServerConfigurations.Count
        $p2sVpnServerConfig2 = Get-AzureRmVirtualWanP2SVpnServerConfiguration -Name $p2sVpnServerConfiguration2Name -VirtualWanId $virtualWan.Id
        Assert-AreEqual $p2sVpnServerConfiguration2Name $p2sVpnServerConfig2.Name
        Assert-AreEqual "TestRadiusServer" $p2sVpnServerConfig2.RadiusServerAddress
 
        # Update existing P2SVpnServerConfiguration using Set-AzureRmVirtualWanP2SVpnServerConfiguration
        $p2sVpnServerConfig2.RadiusServerAddress = "TestRadiusServer1"
        $updatedP2SVpnServerConfig2 = Set-AzureRmVirtualWanP2SVpnServerConfiguration -Name $p2sVpnServerConfiguration2Name -ResourceGroupName $rgName -VirtualWanName -ParentResourceName $virtualWanName -P2SVpnServerConfigurationToSet $p2sVpnServerConfig2
        # $updatedP2SVpnServerConfig2 = Set-AzureRmVirtualWanP2SVpnServerConfiguration -P2SVpnServerConfiguration -P2SVpnServerConfigurationToSet $p2sVpnServerConfig2
        # $updatedP2SVpnServerConfig2 = Set-AzureRmVirtualWanP2SVpnServerConfiguration -P2SVpnServerConfigurationId -P2SVpnServerConfigurationToSet $p2sVpnServerConfig2
        $p2sVpnServerConfig2 = Get-AzureRmVirtualWanP2SVpnServerConfiguration -Name $p2sVpnServerConfiguration2Name -VirtualWanId $virtualWan.Id
        Assert-AreEqual $p2sVpnServerConfiguration2Name $p2sVpnServerConfig2.Name
        Assert-AreEqual "TestRadiusServer1" $p2sVpnServerConfig2.RadiusServerAddress
 
        # Update existing P2SVpnGateway to attach P2SVpnServerConfiguration2 using Set-AzureRmP2SVpnGateway
        $updatedP2SVpnGateway = Set-AzureRmP2SVpnGateway -Name $P2SvpnGatewayName -ResourceGroupName $rgName -P2SVpnServerConfiguration $p2sVpnServerConfig2
        Assert.AreEqual $p2sVpnServerConfig2.Name $updatedP2SVpnGateway.P2SVpnServerConfiguration.Name
 
        # Generate vpn profile again using Get-AzureRmP2SVpnGatewayVpnProfile
        $vpnProfileResponse = Get-AzureRmP2SVpnGatewayVpnProfile -Name $p2sVpnGatewayName -ResourceGroupName $rgName -AuthenticationMethod $vpnclientAuthMethod
        Write-Host $vpnProfilePackageUrl.ProfileUrl
    }
    finally
    {
        # Delete P2SVpnGateway using Remove-AzureRmP2SVpnGateway
        $delete = Remove-AzureRmP2SVpnGateway -Name $p2sVpnGatewayName -ResourceGroupName $rgName
        Assert-AreEqual $True $delete
		$list = Get-AzureRmP2SVpnGateway -ResourceGroupName $rgName
        Assert-AreEqual 0 @($list).Count
 
        # Delete P2SVpnServerConfiguration2 using Remove-AzureRmVirtualWanP2SVpnServerConfiguration
        $delete = Remove-AzureRmVirtualWanP2SVpnServerConfiguration -Name $p2sVpnServerConfiguration2Name -ResourceGroupName $rgName -ParentResourceName $virtualWanName
        Assert-AreEqual $True $delete
 
        # Verify P2SVpnServerConfiguration1 is still associated with the Virtual wan
        $virtualWan = Get-AzureRmVirtualWan -ResourceGroupName $rgName -Name $virtualWanName
        $p2sVpnServerConfig1 = Get-AzureRmVirtualWanP2SVpnServerConfiguration -Name $p2sVpnServerConfiguration1Name -VirtualWan $virtualWan
        Assert-AreEqual $p2sVpnServerConfiguration1Name $p2sVpnServerConfig1.Name
        $list = Get-AzureRmVirtualWanP2SVpnServerConfiguration -VirtualWan $virtualWan
        Assert-AreEqual 1 @($list).Count
 
        # Delete Virtual hub
        $delete = Remove-AzureRmVirtualHub -ResourceGroupName $rgname -Name $virtualHubName
        Assert-AreEqual $True $delete
 
        # Delete Virtual wan and check associated P2SVpnServerConfiguration1 also gets deleted.
        $delete = Remove-AzureRmVirtualWan -InputObject $virtualWan
        Assert-AreEqual $True $delete
        $list = Get-AzureRmVirtualWan -ResourceGroupName $rgName
        Assert-AreEqual 0 @($list).Count
    }
}