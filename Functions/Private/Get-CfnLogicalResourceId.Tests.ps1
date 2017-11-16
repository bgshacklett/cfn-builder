$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe 'Get-CfnStackResources' {

  function Get-CfnStackResources {}

  Mock Get-CfnStackResources {
    (
      Get-Content -Raw -Path "$here\mock\cfnSecurityGroups.json" `
      | ConvertFrom-Json
    )
  }

  It 'Returns the Correct Logical ID' {

    $testArgs =
    @{
      'PhysicalResourceId' = 'sg-ca1d50a2'
      'StackName'          = 'Foo'
      'Region'             = 'Bar'
    }

    Get-CfnLogicalResourceId @testArgs | Should Be 'NFSSecurityGroup'
  }
}
