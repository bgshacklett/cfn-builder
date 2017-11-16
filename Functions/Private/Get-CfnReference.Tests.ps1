$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe 'Get-CfnReference' {

  Function Get-CfnLogicalResourceId {}
  Mock Get-CfnLogicalResourceId { 'LogicalResourceId' }

  Context 'Looking for a valid resource' {

    $testArgs =
    @{
      'PhysicalResourceId' = 'Foo'
      'StackName'          = 'Bar'
      'Region'             = 'test'
    }

    It 'Returns a hashtable representation of a Cfn "Ref"' {

      $result = Get-CfnReference @testArgs

      $result.GetType().FullName | Should Be 'System.Collections.Hashtable'
      $result.Ref | Should Be 'LogicalResourceId'
    }
  }

  Context 'Looking for a resource which does not exist' {

    # Get-CfnLogicalResourceId won't return anything in this case.
    Mock Get-CfnLogicalResourceId {}

    $testArgs =
    @{
      'PhysicalResourceId' = 'Foo'
      'StackName'          = 'Bar'
      'Region'             = 'test'
    }


    It 'Returns nothing.' {

      Get-CfnReference @testArgs | Should Be $null
    }
  }
}
