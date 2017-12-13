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
    $stackContext =
    @{
      'Region'    = $Region
      'StackName' = $StackName
    }

    Write-Verbose ('Getting the Cfn Logical Resource ID of "{0}" in stack "{1}".' -f $PhysicalResourceId, $StackName)
  }

  Process
  {
    @(
      (
        Get-CfnStackResources @stackContext `
        | Where-Object { $_.PhysicalResourceId -eq $PhysicalResourceId } `
        | Select-Object -ExpandProperty LogicalResourceId
      ),
      (
        Get-CfnStack @stackContext `
        | Select-Object -ExpandProperty Parameters `
        | Where-Object { $_.ParameterValue -eq $PhysicalResourceId } `
        | Select-Object -ExpandProperty ParameterKey
      ) `
      -ne $null
    ) `
    | Select-Object -First 1
  }

  End {}
}

