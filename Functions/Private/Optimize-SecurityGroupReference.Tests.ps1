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
    'Region'      = 'us-east-1'
    'StackName'   = 'foo'
    'ErrorAction' = 'Stop'
  }

  $refList =
  @{
    'vpc-12345678' = 'VpcId'
  }

  $mockResourceHash =
  @{
    'MockSecurityGroup' = @{
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
  }

  $inputObject = $mockResourceHash.GetEnumerator()


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

    $result = $inputObject | Optimize-SecurityGroupReference @testArgs

    (
      $result.GetEnumerator() | Select-Object -ExpandProperty Value
    )['Properties']['SecurityGroupIngress'].Length `
    | Should -Be $mockResourceHash['MockSecurityGroup']['Properties']['SecurityGroupIngress'].Length

    (
      $result.GetEnumerator() | Select-Object -ExpandProperty Value
    )['Properties']['SecurityGroupEgress'].Length `
    | Should -Be $mockResourceHash['MockSecurityGroup']['Properties']['SecurityGroupEgress'].Length
  }


  It 'Retains Tags' {

    $expected = @(@{ 'Key' = 'foo'; 'Value' = 'bar' })

    $simpleResourceHash =
    @{
      'MockSecurityGroup' = @{
        'Type'       = 'AWS::EC2::SecurityGroup'
        'Properties' =
        @{
          'Tags' = @(@{ 'Key' = 'foo'; 'Value' = 'bar' })
        }
      } `
    }

    $inputObject = $simpleResourceHash.GetEnumerator()

    $actual = $inputObject `
              | Optimize-SecurityGroupReference @testArgs `
              | ForEach-Object { [PSCustomObject]$_ } `
              | Select-Object -ExpandProperty MockSecurityGroup `
              | ForEach-Object { [PSCustomObject]$_ } `
              | Select-Object -ExpandProperty Properties `
              | ForEach-Object { [PSCustomObject]$_ } `
              | Select-Object -ExpandProperty Tags

    $actual['Key']   | Should Be 'foo'
    $actual['Value'] | Should Be 'bar'
  }


  It 'Retains the Group Description' {

    $simpleResourceHash =
    @{
      'MockSecurityGroup' = @{
        'Type'       = 'AWS::EC2::SecurityGroup'
        'Properties' =
        @{
          'GroupDescription' = 'My Super Awesome Security Group'
        }
      }
    }

    $inputObject = $simpleResourceHash.GetEnumerator()

    $actual = $inputObject `
              | Optimize-SecurityGroupReference @testArgs `
              | ForEach-Object { [PSCustomObject]$_ } `
              | Select-Object -ExpandProperty MockSecurityGroup `
              | ForEach-Object { [PSCustomObject]$_ } `
              | Select-Object -ExpandProperty Properties `
              | ForEach-Object { [PSCustomObject]$_ } `
              | Select-Object -ExpandProperty GroupDescription `
              | Should Be 'My Super Awesome Security Group'
  }


  Context 'Tags are Null' {

    $simpleResourceHash =
    @{
      'MockSecurityGroup' = @{
        'Properties' = @{
          'SecurityGroupEgress' = @(
            @{ 'DestinationSecurityGroupId' = 'sg-12345678' }
          )
          'VpcId' = 'vpc-12345678'
        }
      }
    }

    $inputObject = $simpleResourceHash.GetEnumerator()

    It 'Does not throw an error' {

      {
        $inputObject `
        | Optimize-SecurityGroupReference @testArgs
      } `
      | Should Not Throw
    }
  }


  Context 'SecurityGroupIngress is null' {

    $simpleResourceHash =
    @{
      'MockSecurityGroup' = @{
        'Properties' = @{
          'SecurityGroupEgress' = @(
            @{ 'DestinationSecurityGroupId' = 'sg-12345678' }
          )
          'VpcId' = 'vpc-12345678'
        }
      }
    }

    $inputObject = $simpleResourceHash.GetEnumerator()


    It 'Does not throw an error' {

      {
        $inputObject `
        | Optimize-SecurityGroupReference -Region us-east-1 -StackName foo
      } `
      | Should Not Throw
    }
  }


  Context 'SecurityGroupEgress is null' {

    $simpleResourceHash =
    @{
      'MockSecurityGroup' = @{
        'Properties' = @{
          'SecurityGroupIngress' = @(
            @{ 'SourceSecurityGroupId' = 'sg-12345678' }
          )
          'VpcId' = 'vpc-12345678'
        }
      }
    }

    $inputObject = $simpleResourceHash.GetEnumerator()


    It 'Does not throw an error' {

      {
        $inputObject `
        | Optimize-SecurityGroupReference -Region us-east-1 -StackName foo
      } `
      | Should Not Throw
    }
  }


  Context 'Both SecurityGroupIngress & SecurityGroupEgress are null.' { 

    $simpleResourceHash =
    @{
      'MockSecurityGroup' = @{
        'Properties' = @{
          'SecurityGroupIngress' = @(
            @{ 'SourceSecurityGroupId' = 'sg-12345678' }
          )
          'VpcId' = 'vpc-12345678'
        }
      }
    }

    $inputObject = $simpleResourceHash.GetEnumerator()


    It 'Does not throw an error' {

      {
        $inputObject `
        | Optimize-SecurityGroupReference @testArgs
      } `
      | Should Not Throw
    }
  }


  Context 'The VPC ID _is_ Available as a Parameter' {

    Mock Get-CfnReference { @{ 'Ref' = $refList[$PhysicalResourceId] } }

    $simpleResourceHash =
    @{
      'MockSecurityGroup' = @{
        'Properties' = @{
          'SecurityGroupIngress' = @(
            @{ 'SourceSecurityGroupId' = 'sg-12345678' }
          )
          'VpcId' = 'vpc-12345678'
        }
      }
    }

    $inputObject = $simpleResourceHash.GetEnumerator()


    It 'Replaces the Vpc ID with a Ref' {
      
      (
        (
          $inputObject | Optimize-SecurityGroupReference @testArgs
        ).GetEnumerator() `
        | Select-Object -ExpandProperty Value
      )['Properties']['VpcId'] `
      | Should -BeLike @{ 'Ref' = $refList['vpc-12345678'] }
    }
  }


  Context 'The VPC ID is _Not_ Available as a Parameter.' {

    $simpleResourceHash =
    @{
      'MockSecurityGroup' = @{
        'Properties' = @{
          'SecurityGroupIngress' = @(
            @{ 'SourceSecurityGroupId' = 'sg-12345678' }
          )
          'VpcId' = 'vpc-12345678'
        }
      }
    }

    $inputObject = $simpleResourceHash.GetEnumerator()


    It 'Passes the VpcId property back untouched.' {

      (
        (
          $inputObject | Optimize-SecurityGroupReference @testArgs
        ).GetEnumerator() `
        | Select-Object -ExpandProperty Value
      )['Properties']['VpcId'] `
      | Should -Be $mockResourceHash['MockSecurityGroup']['Properties']['VpcId']
    }
  }


  Context 'The Function Called Without the Region Parameter' {

    It 'Throws an Error' {

      {
        $inputObject `
        | Optimize-SecurityGroupReference -StackName foo
      } `
      | Should Throw
    }
  }


  Context 'The Function Called Without the StackName Parameter' {

    It 'Throws an Error' {

      {
        $inputObject `
        | Optimize-SecurityGroupReference -Region foo
      } `
      | Should Throw
    }
  }
}
#endregion
