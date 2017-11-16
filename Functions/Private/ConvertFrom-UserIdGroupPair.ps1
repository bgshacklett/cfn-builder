function ConvertFrom-UserIdGroupPair
{
  [CmdletBinding()]
  Param
  (
    $GroupId,
    $Region,
    $StackName
  )

  Begin {}

  Process
  {
    Write-Debug ('Searching for the SG {0} in the Stack "{1}".' `
                   -f $GroupId, $StackName)

    $refQueryParams =
    @{
      'Region'             = $Region
      'StackName'          = $StackName
      'PhysicalResourceId' = $GroupId
    }
    # Return either a 'Ref' or the Group ID if the Ref is null.
    ((Get-CfnReference @refQueryParams),$GroupId -ne $null)[0]
  }

  End {}
}

