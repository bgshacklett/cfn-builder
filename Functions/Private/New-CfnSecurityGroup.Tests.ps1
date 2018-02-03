#region Test Environment Setup
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
$deps = 'ConvertTo-SecurityGroupRuleSet',
        'Get-CfnLogicalResourceId'

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


#region Tests
Describe 'New-CfnSecurityGroup' {

  $MockSGName = 'MockSecurityGroup'

  Mock 'ConvertTo-SecurityGroupRuleSet'
  Mock 'Get-CfnLogicalResourceId' { $MockSGName }

  Context 'Security Group Has Multiple Valid Tags' {

    $MockSecurityGroup =
    @{
      'GroupDescription' = 'Mock Security Group'
      'GroupId'          = 'sg-01234567'
      'GroupName'        = $MockSGName
      'OwnerId'          = '012345678901'
      'IpPermission'     = @(
        @{
          'IpRanges'         = @()
          'FromPort'         = 22
          'IpProtocol'       = 'tcp'
          'Ipv4Ranges'       = @()
          'Ipv6Ranges'       = @()
          'PrefixListIds'    = @()
          'ToPort'           = 22
          'UserIdGroupPairs' = @(
            @{
              'Description'            = $null
              'GroupId'                = 'sg-1234578'
              'GroupName'              = $null
              'PeeringStatus'          = $null
              'UserId'                 = '012345678901'
              'VpcId'                  = $null
              'VpcPeeringConnectionId' = $null
            }
          )
        }
      )
      'Tags'             = [Amazon.Ec2.Model.Tag[]]@(
        @{
          'Key'   = 'Key1'
          'Value' = 'Value1'
        },
        @{
          'Key'   = 'Key2'
          'Value' = 'Value2'
        }
      )
      'VpcId'            = 'vpc-01234567'
    }

    $TestContext =
    @{
      'Region'    = 'us-east-1'
      'StackName' = 'TestStack'
    }

    It 'Preserves the Tags' {

      (
        $MockSecurityGroup `
        | New-CfnSecurityGroup @TestContext
      )[$MockSGName]['Properties']['Tags'] `
      | Should -Not -BeNullOrEmpty
    }

    It 'Returns the Tags as a List of Objects' {

      $MockSecurityGroup `
      | New-CfnSecurityGroup @TestContext `
      | ConvertTo-Json -Depth 99 `
      | Write-Host

      (
        $MockSecurityGroup `
        | New-CfnSecurityGroup @TestContext
      )[$MockSGName]['Properties']['Tags'].GetType().BaseType.Name `
      | Should -Be 'Array'
    }
  }


  Context 'Security Group Has a Single Valid Tag' {

    $MockSecurityGroup =
    @{
      'GroupDescription' = 'Mock Security Group'
      'GroupId'          = 'sg-01234567'
      'GroupName'        = $MockSGName
      'OwnerId'          = '012345678901'
      'IpPermission'     = @(
        @{
          'IpRanges'         = @()
          'FromPort'         = 22
          'IpProtocol'       = 'tcp'
          'Ipv4Ranges'       = @()
          'Ipv6Ranges'       = @()
          'PrefixListIds'    = @()
          'ToPort'           = 22
          'UserIdGroupPairs' = @(
            @{
              'Description'            = $null
              'GroupId'                = 'sg-1234578'
              'GroupName'              = $null
              'PeeringStatus'          = $null
              'UserId'                 = '012345678901'
              'VpcId'                  = $null
              'VpcPeeringConnectionId' = $null
            }
          )
        }
      )
      'Tags'             = [Amazon.Ec2.Model.Tag[]]@(
        @{
          'Key'   = 'Key1'
          'Value' = 'Value1'
        }
      )
      'VpcId'            = 'vpc-01234567'
    }

    $TestContext =
    @{
      'Region'    = 'us-east-1'
      'StackName' = 'TestStack'
    }

    It 'Preserves the Tags' {

      (
        $MockSecurityGroup `
        | New-CfnSecurityGroup @TestContext
      )[$MockSGName]['Properties']['Tags'] `
      | Should -Not -BeNullOrEmpty
    }

    It 'Returns the Tags as a List of Objects' {

      $MockSecurityGroup `
      | New-CfnSecurityGroup @TestContext `
      | ConvertTo-Json -Depth 99 `
      | Write-Host

      (
        $MockSecurityGroup `
        | New-CfnSecurityGroup @TestContext
      )[$MockSGName]['Properties']['Tags'].GetType().BaseType.Name `
      | Should -Be 'Array'
    }
  }
}
#endregion
