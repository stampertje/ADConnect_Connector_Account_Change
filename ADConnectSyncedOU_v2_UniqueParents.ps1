[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]
    $inputfile,

    [Parameter()]
    [string]
    $outputfile
)

$syncscope = Get-Content $inputfile | ConvertFrom-Json

$allDomainSyncInfo = @()

Foreach ($connector in $syncscope)
{

  $domlen = $connector.domainName.split(".").count # determining how many domain components are in the DN
  $domainDN = "DC=" + ($connector.domainName.split(".") -join ",DC=")

  $AllSyncedOU = $connector.syncedOU

  $FilteredOUList = @()

  Foreach ($SyncedOU in $AllSyncedOU)
  {
    $SyncedOU_Array = $SyncedOU.split(",")

    # Not evaluating the domain components from the OUArray, $LengthOfOUComponents is the first item in the array representing an OU
    $LengthOfOUComponents = $SyncedOU_Array.count - ($domlen + 1)
    $parentfound = $false

    # If there is only 1 array item then the ou is in the root of the domain
    if ($LengthOfOUComponents -eq 0)
    {
      if (-not($FilteredOUList.Contains($SyncedOU)))
      {
        $parentfound = $true
        $FilteredOUList += $SyncedOU
      }
    }

    # Create the tree for the current OU
    $OUTree_Array =@()
    If ($LengthOfOUComponents -gt 0)
    {
      $PartOfOUDN = $null
      for ($i = $LengthOfOUComponents; $i -le $LengthOfOUComponents -and $i -ge 0; $i--)
      {
        If ($null -eq $partofOUDN)
        {
          $PartOfOUDN = $SyncedOU_Array[$i] + $partofOUDN + "," + $domainDN
        } Else {
          $PartOfOUDN = $SyncedOU_Array[$i] + "," + $partofOUDN
        }
        $OUTree_Array += $PartOfOUDN
      }
    }

    # Check for each of the OUs in the tree if that is marked for sync
    # The highest OU in the tree that is synced is added to the list
    For ($i = 0; $i -le $OUTree_Array.count-1; $i++)
    {
      if ($FilteredOUList.IndexOf($OUTree_Array[$i]) -ge 0)
      {
        $parentfound = $true
      }

      if ($AllSyncedOU.IndexOf($OUTree_Array[$i]) -ge 0)
      {
        if ($parentfound -eq $false)
        {
          if ($FilteredOUList.IndexOf($OUTree_Array[$i]) -lt 0)
          {
            $parentfound = $true
            $FilteredOUList += $OUTree_Array[$i]
          } 
        }
      }
    }
  }

  $domainSyncInfo = [PSCustomObject]@{
    connectorName = $connector.connectorName
    domainName = $connector.domainName
    syncedOU = $FilteredOUList
  }

  $allDomainSyncInfo += $domainSyncInfo
}

If ($outputfile -ne "")
{
  $allDomainSyncInfo | ConvertTo-Json | Out-File $outputfile
} else {
  $allDomainSyncInfo
}