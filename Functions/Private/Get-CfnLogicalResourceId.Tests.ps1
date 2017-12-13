#region Test Environment Setup
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
$deps = $null

. "$here\$sut"

foreach ($dep in $deps)
{
  $depPath = $here `
             | Split-Path -Parent `
             | Get-ChildItem -Recurse -Include ($dep + '.ps1') `
             | Select-Object -ExpandProperty FullName

  Write-Host $here
  Write-Host $dep

  . $depPath
}


# Stub third party functions out so that they can be mocked.
function Get-CfnStackResources { Param($Region, $StackName) }
function Get-CfnStack          { Param($Region, $StackName) }
#endregion


#region Test Logic
Describe 'Get-CfnLogicalResourceId' {

  Context 'The PhysicalResourceId is Found as a Resource in the Stack:' {

    Mock Get-CfnStack {}

    Mock Get-CfnStackResources {

      [PSCustomObject]@{
        'LogicalResourceId'  = 'MSSQLSecurityGroup'
        'PhysicalResourceId' = 'sg-12345678'
      },
      [PSCustomObject]@{
        'LogicalResourceId'  = 'NFSSecurityGroup'
        'PhysicalResourceId' = 'sg-23456789'
      },
      [PSCustomObject]@{
        'LogicalResourceId'  = 'OracleSecurityGroup'
        'PhysicalResourceId' = 'sg-34567890'
      }
    }


    It 'Returns the Correct Logical ID' {

      $testArgs =
      @{
        'PhysicalResourceId' = 'sg-23456789'
        'StackName'          = 'Foo'
        'Region'             = 'Bar'
      }

      Write-Host ('StackResources:' + (Get-CfnLogicalResourceId @testArgs))
      Get-CfnLogicalResourceId @testArgs | Should Be 'NFSSecurityGroup'
    }
  }


  Context 'The PhysicalResourceId is the Value of a Parameter of the Stack:' {

    Mock Get-CfnStackResources

    Mock Get-CfnStack {

      [PSCustomObject]@{
        'Parameters' = @(
          [PSCustomObject]@{
            'ParameterKey'   = 'PeerSecurityGroupId'
            'ParameterValue' = 'sg-23456789'
          },
          [PSCustomObject]@{
            'ParameterKey'   = 'VpcId'
            'ParameterValue' = 'vpc-12345678'
          },
          [PSCustomObject]@{
            'ParameterKey'   = 'PeerVpcId'
            'ParameterValue' = 'vpc-23456789'
          }
        )
      }
    }


    It 'Returns the Parameter Key' {

      $testArgs =
      @{
        'PhysicalResourceId' = 'vpc-12345678'
        'StackName'          = 'Foo'
        'Region'             = 'Bar'
      }
      Get-CfnLogicalResourceId @testArgs | Should Be 'VpcId'
    }
  }


  Context 'The PhysicalResourceId is Both a Param And a LocigalResourceId:' {

    Mock Get-CfnStackResources {

      @(
        [PSCustomObject]@{
          'LogicalResourceId'  = 'ResMSSQLSecurityGroup'
          'PhysicalResourceId' = 'sg-12345678'
        },
        [PSCustomObject]@{
          'LogicalResourceId'  = 'ResNFSSecurityGroup'
          'PhysicalResourceId' = 'sg-23456789'
        },
        [PSCustomObject]@{
          'LogicalResourceId'  = 'ResOracleSecurityGroup'
          'PhysicalResourceId' = 'sg-34567890'
        }
      )
    }

    Mock Get-CfnStack {

      [PSCustomObject]@{
        'Parameters' = @(
          [PSCustomObject]@{
            'ParameterKey'    = 'ParamMSSQLSecurityGroup'
            'ParameterValue'  = 'sg-12345678'
          },
          [PSCustomObject]@{
            'ParameterKey'    = 'ParamNFSSecurityGroup'
            'ParameterValue'  = 'sg-23456789'
          },
          [PSCustomObject]@{
            'ParameterKey'    = 'ParamOracleSecurityGroup'
            'ParameterValue'  = 'sg-34567890'
          }
        )
      }
    }


    It 'Returns the Parameter Key' {

      $testArgs =
      @{
        'PhysicalResourceId' = 'sg-23456789'
        'StackName'          = 'Foo'
        'Region'             = 'Bar'
      }
      Get-CfnLogicalResourceId @testArgs | Should Be 'ResNfsSecurityGroup'
    }
  }


  Context 'The LogicalResourceId is Not Found in the Stacks Resources or Parameters:' {

    Mock Get-CfnStackResources

    Mock Get-CfnStack {

      [PSCustomObject]@{ 'Parameters' = [PSCustomObject]@{} }
    }

    It 'Returns $null' {

      $testArgs =
      @{
        'PhysicalResourceId' = 'sg-ca1d50a2'
        'StackName'          = 'Foo'
        'Region'             = 'Bar'
      }
      Get-CfnLogicalResourceId @testArgs | Should Be $null
    }
  }
}
#endregion
