#region Test Environment Setup
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.','.'
$deps = 'Optimize-SecurityGroupRule',
        'Get-CfnReference'

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
Describe 'Optimize-SecurityGroupReference' {

  $testArgs =
  @{
    'Region'    = 'us-east-1'
    'StackName' = 'foo'
  }

  $refList =
  @{
    'vpc-12345678' = 'VpcId'
  }

  $mockSecurityGroup =
  @{
    'Type'       = 'AWS::EC2::SecurityGroup'
    'Properties' =
    @{
      'SecurityGroupIngress' = @(
        @{
          'ToPort'                = 22
          'IpProtocol'            = 'tcp'
          'SourceSecurityGroupId' = 'sg-12345678'
          'FromPort'              = 22
        },
        @{
          'ToPort'                = 22
          'IpProtocol'            = 'tcp'
          'SourceSecurityGroupId' = 'sg-12345677'
          'FromPort'              = 22
        },
        @{
          'ToPort'                = 22
          'IpProtocol'            = 'tcp'
          'SourceSecurityGroupId' = 'sg-12345676'
          'FromPort'              = 22
        }
      )
      'SecurityGroupEgress' = @(
        @{
          'ToPort'                     = 22
          'IpProtocol'                 = 'tcp'
          'DestinationSecurityGroupId' = 'sg-12345675'
          'FromPort'                   = 22
        },
        @{
          'ToPort'                     = 22
          'IpProtocol'                 = 'tcp'
          'DestinationSecurityGroupId' = 'sg-12345674'
          'FromPort'                   = 22
        },
        @{
          'ToPort'                     = 22
          'IpProtocol'                 = 'tcp'
          'DestinationSecurityGroupId' = 'sg-12345673'
          'FromPort'                   = 22
        }
      )
      'VpcId'                = 'vpc-12345678'
      'Tags'                 = @(
                                 @{ 'Key' = 'foo'; 'Value' = 'bar' }
                                 @{ 'Key' = 'baz'; 'Value' = 'qux' }
                               )
      'GroupDescription'     = 'My super fantastic security group'
    }
  }


  Mock Optimize-SecurityGroupRule {

    @{
      'ToPort'                     = 22
      'IpProtocol'                 = 'tcp'
      'SourceSecurityGroupId'      = @{ 'Ref' = 'MySourceSecurityGroup' }
      'DestinationSecurityGroupId' = @{ 'Ref' = 'MyDestinationSecurityGroup' }
      'FromPort'                   = 22
    }
  }

  Mock Get-CfnReference


  It 'Returns the Same Number of Rules as it Receives' {

    $result = $mockSecurityGroup | Optimize-SecurityGroupReference @testArgs

    $result['SecurityGroupIngress'].Length `
    | Should -Be $mockSecurityGroup['SecurityGroupIngress'].Length

    $result['SecurityGroupEgress'].Length `
    | Should -Be $mockSecurityGroup['SecurityGroupEgress'].Length
  }


  It 'Retains Tags' {

    $expected = @(@{ 'Key' = 'foo'; 'Value' = 'bar' })
  
    $actual =
    @{
      'Type'       = 'AWS::EC2::SecurityGroup'
      'Properties' =
      @{
        'Tags' = @(@{ 'Key' = 'foo'; 'Value' = 'bar' })
      }
    } `
    | Optimize-SecurityGroupReference -Region us-east-1 -StackName foo `
    | ForEach-Object { [PSCustomObject]$_ } `
    | Select-Object -ExpandProperty Properties `
    | ForEach-Object { [PSCustomObject]$_ } `
    | Select-Object -ExpandProperty Tags

    $actual['Key']   | Should Be 'foo'
    $actual['Value'] | Should Be 'bar'
  }


  It 'Retains the Group Description' {

    @{
      'Type'       = 'AWS::EC2::SecurityGroup'
      'Properties' =
      @{
        'GroupDescription' = 'My Super Awesome Security Group'
      }
    } `
    | Optimize-SecurityGroupReference -Region us-east-1 -StackName foo `
    | ForEach-Object { [PSCustomObject]$_ } `
    | Select-Object -ExpandProperty Properties `
    | ForEach-Object { [PSCustomObject]$_ } `
    | Select-Object -ExpandProperty GroupDescription `
    | Should Be 'My Super Awesome Security Group'
  }

  
  Context 'SecurityGroupIngress is null' {

    $simpleSecurityGroup =
    @{
      'Properties' =
      @{
        'SecurityGroupEgress' = @(
          @{
            'DestinationSecurityGroupId' = 'sg-12345678'
          }
        )
        'VpcId' = 'vpc-12345678'
      }
    }


    It 'Does not throw an error' {

      {
        $simpleSecurityGroup `
        | Optimize-SecurityGroupReference -Region us-east-1 -StackName foo
      } `
      | Should Not Throw
    }
  }


  Context 'SecurityGroupEgress is null' {

    $simpleSecurityGroup =
    @{
      'Properties' =
      @{
        'SecurityGroupIngress' = @(
          @{
            'SourceSecurityGroupId' = 'sg-12345678'
          }
        )
        'VpcId' = 'vpc-12345678'
      }
    }


    It 'Does not throw an error' {

      {
        $simpleSecurityGroup `
        | Optimize-SecurityGroupReference -Region us-east-1 -StackName foo
      } `
      | Should Not Throw
    }
  }


  Context 'Both SecurityGroupIngress & SecurityGroupEgress are null.' { 

    $simpleSecurityGroup =
    @{
      'Properties' = @{ 'VpcId' = 'vpc-12345678' }
    }


    It 'Does not throw an error' {

      {
        $simpleSecurityGroup `
        | Optimize-SecurityGroupReference -Region us-east-1 -StackName foo
      } `
      | Should Not Throw
    }
  }


  Context 'The VPC ID _is_ Available as a Parameter' {

    Mock Get-CfnReference { @{ 'Ref' = $refList[$PhysicalResourceId] } }

    It 'Replaces the Vpc ID with a Ref' {

      (
        $mockSecurityGroup | Optimize-SecurityGroupReference @testArgs
      )['Properties']['VpcId'] `
      | Should -BeLike @{ 'Ref' = $refList['vpc-12345678'] }
    }
  }


  Context 'The VPC ID is _Not_ Available as a Parameter.' {

    It 'Passes the VpcId property back untouched.' {

      (
        $mockSecurityGroup | Optimize-SecurityGroupReference @testArgs
      )['Properties']['VpcId'] `
      | Should -Be $mockSecurityGroup['Properties']['VpcId']
    }
  }

  Context 'The Function Called Without the Region Parameter' {

    It 'Throws an Error' {

      {
        $mockSecurityGroup `
        | Optimize-SecurityGroupReference -StackName foo
      } `
      | Should Throw
    }
  }


  Context 'The Function Called Without the StackName Parameter' {

    It 'Throws an Error' {

      {
        $mockSecurityGroup `
        | Optimize-SecurityGroupReference -Region foo
      } `
      | Should Throw
    }
  }
}
#endregion
