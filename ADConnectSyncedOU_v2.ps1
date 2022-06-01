#Requires -Module ActiveDirectory

[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $ADSyncserver,

    [Parameter()]
    [string]
    $outputfile

)

if ($NULL -eq $ADSyncserver){$ADSyncserver = Read-Host -Prompt 'AD Connect Server Name please'}
If ($NULL -eq $outputfile){$outputfile = Read-Host -Prompt 'outputfile fullpath'}

#connect remote posh to ADSync server
$ADConnectOUList = Invoke-Command -ComputerName $ADSyncserver -ScriptBlock {
    
    Import-Module "C:\Program Files\Microsoft Azure AD Sync\Bin\ADSync\ADSync.psd1"
    
    $ADSyncADConnectorSet = (Get-ADSyncConnector | Where-Object {$_.Type -eq "AD"})

    $SyncedOUTable = @()

    Foreach ($Connector in $ADSyncADConnectorSet)
    {
        # loop through connectors

        <#
            $Connector.Name is the forest name
            $connector.partitions are the synced domains in the forest
        #>

        # Loop through partitions in the connector
        Foreach ($Partition in $connector.Partitions)
        {

            $results = [PSCustomObject]@{
                # The inclusions show only the selected top level OUs. To get the full list of selected OUs you 
                # have to loop through the OUs in the domain and remove the exclusions from that list.
                connectorName = $Connector.name
                domainName = $Partition.name
                Exclusions = $Partition.ConnectorPartitionScope.ContainerExclusionList
                Inclusions = $Partition.ConnectorPartitionScope.ContainerInclusionList
            }
            
            $SyncedOUTable += $Results

        }

    }

    Return $SyncedOUTable

}

# Loop through the connected domains
$allDomainSyncInfo = @()

Foreach ($Domain in $ADConnectOUList)
{
    # Go through all the domains to parse the local OU's and add them to an array
    $LocalOU = Get-ADOrganizationalUnit -Filter * -Properties Distinguishedname -server $domain.domainName | Select-Object Distinguishedname
    
    [System.Collections.ArrayList]$IncludedOUList = @()

    Foreach ($IncludedOU in $domain.Inclusions)
    {
        $LocalOU.Distinguishedname | ForEach-Object { if($_ -match "$IncludedOU") {$IncludedOUList.Add("$_")}}
    }

    foreach ($ExcludedOU in $domain.Exclusions)
    {
        $IncludedOUList.Remove($ExcludedOU)
    }

    $domainSyncInfo = [PSCustomObject]@{
        connectorName = $domain.connectorName
        domainName = $domain.domainName
        syncedOU = $IncludedOUList
    }

    $allDomainSyncInfo += $domainSyncInfo
}


$allDomainSyncInfo | ConvertTo-Json | Out-File $outputfile
