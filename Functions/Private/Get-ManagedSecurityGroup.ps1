function Get-ManagedSecurityGroup
{
  [CmdletBinding()]
  Param
  (
    $Region,
    $StackName
  )


  Begin
  {
    Write-Verbose ('Getting managed Security Groups from the stack "{0}"' -f $StackName)
  }

  Process
  {
    Get-CfnStackResources -Region $Region -StackName $StackName `
    | Where-Object {
      $_.ResourceType -eq 'AWS::EC2::SecurityGroup'
    } `
    | Select-Object -ExpandProperty PhysicalResourceId `
    | Get-Ec2SecurityGroup -Region $Region
  }

  End {}
}

