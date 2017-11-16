function Get-CfnReference
{
  [CmdletBinding()]
  Param
  (
    $PhysicalResourceId,
    $StackName,

    [Parameter(Mandatory=$true)]
    $Region
  )

  Begin {}

  Process
  {
    $resourceQueryParams =
    @{
      'Region'             = $Region
      'StackName'          = $StackName
      'PhysicalResourceId' = $PhysicalResourceId
    }
    $logicalResourceId = Get-CfnLogicalResourceId @resourceQueryParams


    # Return a 'Ref' hashtable, but only if it's not null
    @{ 'Ref' = $logicalResourceId } | Where-Object { $_.Ref }
  }

  End {}
}

