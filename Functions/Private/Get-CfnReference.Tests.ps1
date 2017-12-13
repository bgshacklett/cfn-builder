#region Test Environment Setup
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
$deps = 'Get-CfnLogicalResourceId'

. "$here\$sut"

foreach ($dep in $deps)
{
  $depPath = $here `
             | Split-Path -Parent `
             | Get-ChildItem -Recurse -Include ($dep + '.ps1') `
             | Select-Object -ExpandProperty FullName

  . $depPath
}
#endregion


#region Test Logic
Describe 'Get-CfnReference' {

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
#endregion
