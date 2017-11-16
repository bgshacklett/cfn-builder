function Get-CfnLogicalResourceId
{
  [CmdletBinding()]
  Param
  (
    $PhysicalResourceId,
    $StackName,

    [Parameter(Mandatory=$true)]
    $Region
  )

  Begin
  {
    Write-Verbose ('Getting the Cfn Logical Resource ID of "{0}" in stack "{1}".' -f $PhysicalResourceId, $StackName)
  }

  Process
  {
    Get-CfnStackResources -Region $Region -StackName $StackName `
    | Where-Object { $_.PhysicalResourceId -eq $PhysicalResourceId } `
    | Select-Object -ExpandProperty LogicalResourceId
  }

  End {}
}

