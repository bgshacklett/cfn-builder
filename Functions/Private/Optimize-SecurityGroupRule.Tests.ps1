#region Test Environment Setup
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
$deps = 'Get-CfnReference'

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
Describe 'Optimize-SecurityGroupRule' {

  Context 'Ref _is_ available' {

    $refMap =
    @{
      '127.0.0.1/32'        = 'MyCidrIp'
      '::1/128'             = 'MyCidrIpv6'
      'sg-12345678'         = 'MySecurityGroup'
      'MySecurityGroupName' = 'MySecurityGroup'
      'pl-12345678'         = 'MyDestinationPrefixList'
    }

    Mock Get-CfnReference { @{ 'Ref' = ($refMap[$PhysicalResourceId]) } }


    Context 'OmniDirectional' {

      Context 'By CidrIp' {

        $rule =
        @{
          'ToPort'     = 22
          'IpProtocol' = 'tcp'
          'CidrIp'     = '127.0.0.1/32'
          'FromPort'   = 22
        }


        It 'Returns a Reference to the Logical ID of the Resource.' {

          $expected =
          @{
            'ToPort'     = 22
            'IpProtocol' = 'tcp'
            'CidrIp'     = @{ 'Ref' = ($refMap['127.0.0.1/32']) }
            'FromPort'   = 22
          }

          $testParams =
          @{
            'Region'    = 'us-east-1'
            'StackName' = 'foo'
          }
          $actual = $rule | Optimize-SecurityGroupRule @testParams

          $actual['ToPort']     | Should -Be     $expected['ToPort']
          $actual['IpProtocol'] | Should -Be     $expected['IpProtocol']
          $actual['FromPort']   | Should -Be     $expected['FromPort']
          $actual['CidrIp']     | Should -BeLike $expected['CidrIp']
        }
      }


      Context 'By CidrIpv6' {

        $rule =
        @{
          'ToPort'     = 22
          'IpProtocol' = 'tcp'
          'CidrIpv6'   = '::1/128'
          'FromPort'   = 22
        }


        It 'Returns a Reference to the Logical ID of the Resource.' {

          $expected =
          @{
            'ToPort'     = 22
            'IpProtocol' = 'tcp'
            'CidrIpv6'   = @{ 'Ref' = ($refMap['::1/128']) }
            'FromPort'   = 22
          }

          $testParams =
          @{
            'Region'    = 'us-east-1'
            'StackName' = 'foo'
          }
          $actual = $rule | Optimize-SecurityGroupRule @testParams

          $actual['ToPort']     | Should -Be     $expected['ToPort']
          $actual['IpProtocol'] | Should -Be     $expected['IpProtocol']
          $actual['FromPort']   | Should -Be     $expected['FromPort']
          $actual['CidrIpv6']   | Should -BeLike $expected['CidrIpv6']
        }
      }

    }


    Context 'Ingress' {

      Context 'By SourceSecurityGroupId.' {

        $rule =
        @{
          'ToPort'                = 22
          'IpProtocol'            = 'tcp'
          'SourceSecurityGroupId' = 'sg-12345678'
          'FromPort'              = 22
        }


        It 'Returns a Reference to the Logical ID of the Resource.' {

          $expected =
          @{
            'ToPort'                = 22
            'IpProtocol'            = 'tcp'
            'SourceSecurityGroupId' = @{ 'Ref' = ($refMap['sg-12345678']) }
            'FromPort'              = 22
          }

          $testParams =
          @{
            'Region'    = 'us-east-1'
            'StackName' = 'foo'
          }
          $actual = $rule | Optimize-SecurityGroupRule @testParams

          $actual['ToPort']     | Should -Be $expected['ToPort']
          $actual['IpProtocol'] | Should -Be $expected['IpProtocol']
          $actual['FromPort']   | Should -Be $expected['FromPort']
          $actual['SourceSecurityGroupId'] `
          | Should -BeLike $expected['SourceSecurityGroupId']
        }
      }


      Context 'By SourceSecurityGroupName; in the default VPC.' {

        $rule =
        @{
          'ToPort'                  = 22
          'IpProtocol'              = 'tcp'
          'SourceSecurityGroupName' = 'MySecurityGroupName'
          'FromPort'                = 22
        }


        It 'Returns a Reference to the Logical ID of the Resource.' {

          $expected =
          @{
            'ToPort'                  = 22
            'IpProtocol'              = 'tcp'
            'SourceSecurityGroupName' = @{
              'Ref' = ($refMap['MySecurityGroupName'])
            }
            'FromPort'                = 22
          }

          $testParams =
          @{
            'Region'    = 'us-east-1'
            'StackName' = 'foo'
          }
          $actual = $rule | Optimize-SecurityGroupRule @testParams

          $actual['ToPort']     | Should -Be $expected['ToPort']
          $actual['IpProtocol'] | Should -Be $expected['IpProtocol']
          $actual['FromPort']   | Should -Be $expected['FromPort']
          $actual['SourceSecurityGroupName'] `
          | Should -BeLike $expected['SourceSecurityGroupName']
        }
      }
    }


    Context 'Egress' {

      Context 'By DestinationSecurityGroupId' {

        $rule =
        @{
          'ToPort'                     = 22
          'IpProtocol'                 = 'tcp'
          'DestinationSecurityGroupId' = 'sg-12345678'
          'FromPort'                   = 22
        }


        It 'Returns a Reference to the Logical ID of the Resource.' {

          $expected =
          @{
            'ToPort'                     = 22
            'IpProtocol'                 = 'tcp'
            'DestinationSecurityGroupId' = @{
              'Ref' = ($refMap['sg-12345678'])
            }
            'FromPort'                   = 22
          }

          $testParams =
          @{
            'Region'    = 'us-east-1'
            'StackName' = 'foo'
          }
          $actual = $rule | Optimize-SecurityGroupRule @testParams

          $actual['ToPort']     | Should -Be $expected['ToPort']
          $actual['IpProtocol'] | Should -Be $expected['IpProtocol']
          $actual['FromPort']   | Should -Be $expected['FromPort']
          $actual['DestinationSecurityGroupId'] `
          | Should -BeLike $expected['DestinationSecurityGroupId']
        }
      }


      Context 'By DestinationSecurityGroupName; in the default VPC' {

        $rule =
        @{
          'ToPort'                       = 22
          'IpProtocol'                   = 'tcp'
          'DestinationSecurityGroupName' = 'MySecurityGroupName'
          'FromPort'                     = 22
        }


        It 'Returns a Reference to the Logical ID of the Resource.' {

          $expected =
          @{
            'ToPort'                       = 22
            'IpProtocol'                   = 'tcp'
            'DestinationSecurityGroupName' = @{
              'Ref' = ($refMap['MySecurityGroupName'])
            }
            'FromPort'                     = 22
          }

          $testParams =
          @{
            'Region'    = 'us-east-1'
            'StackName' = 'foo'
          }
          $actual = $rule | Optimize-SecurityGroupRule @testParams

          $actual['ToPort']     | Should -Be $expected['ToPort']
          $actual['IpProtocol'] | Should -Be $expected['IpProtocol']
          $actual['FromPort']   | Should -Be $expected['FromPort']
          $actual['DestinationSecurityGroupName'] `
          | Should -BeLike $expected['DestinationSecurityGroupName']
        }
      }


      Context 'By DestinationPrefixListId' {

        $rule =
        @{
          'ToPort'                  = 22
          'IpProtocol'              = 'tcp'
          'DestinationPrefixListId' = 'pl-12345678'
          'FromPort'                = 22
        }


        It 'Returns a Reference to the Logical ID of the Resource.' {

          $expected =
          @{
            'ToPort'                  = 22
            'IpProtocol'              = 'tcp'
            'DestinationPrefixListId' = @{ 'Ref' = ($refMap['pl-12345678']) }
            'FromPort'                = 22
          }

          $testParams =
          @{
            'Region'    = 'us-east-1'
            'StackName' = 'foo'
          }
          $actual = $rule | Optimize-SecurityGroupRule @testParams

          $actual['ToPort']     | Should -Be $expected['ToPort']
          $actual['IpProtocol'] | Should -Be $expected['IpProtocol']
          $actual['FromPort']   | Should -Be $expected['FromPort']
          $actual['DestinationPrefixListId'] `
          | Should -BeLike $expected['DestinationPrefixListId']
        }
      }
    }
  }


  Context 'Ref is _not_ available' {

    Mock Get-CfnReference


    Context 'OmniDirectional' {

      Context 'By CidrIp' {

        $rule =
        @{
          'ToPort'     = 22
          'IpProtocol' = 'tcp'
          'FromPort'   = 22
          'CidrIp'     = '127.0.0.1/32'
        }


        It 'Passes the rule through unchanged.' {

          [PSCustomObject](
            $rule `
            | Optimize-SecurityGroupRule -Region us-east-1 -StackName foo
          ) `
          | Should -BeLike ([PSCustomObject]$rule)
        }
      }


      Context 'By CidrIpv6' {

        $rule =
        @{
          'ToPort'       = 22
          'IpProtocol'   = 'tcp'
          'FromPort'     = 22
          'CidrIpv6'     = '::1/128'
        }


        It 'Passes the rule through unchanged.' {

          [PSCustomObject](
            $rule `
            | Optimize-SecurityGroupRule -Region us-east-1 -StackName foo
          ) `
          | Should -BeLike ([PSCustomObject]$rule)
        }
      }
    }


    Context 'Ingress' {

      Context 'By SourceSecurityGroupId' {
        
        $rule =
        @{
          'ToPort'                = 22
          'IpProtocol'            = 'tcp'
          'FromPort'              = 22
          'SourceSecurityGroupId' = 'sg-12345678'
        }


        It 'Passes the rule through unchanged.' {

          [PSCustomObject](
            $rule `
            | Optimize-SecurityGroupRule -Region us-east-1 -StackName foo
          ) `
          | Should -BeLike ([PSCustomObject]$rule)
        }
      }


      Context 'By SourceSecurityGroupName; in the default VPC.' {
        
        $rule =
        @{
          'ToPort'                  = 22
          'IpProtocol'              = 'tcp'
          'FromPort'                = 22
          'SourceSecurityGroupName' = 'MySecurityGroupName'
        }


        It 'Passes the rule through unchanged.' {

          [PSCustomObject](
            $rule `
            | Optimize-SecurityGroupRule -Region us-east-1 -StackName foo
          ) `
          | Should -BeLike ([PSCustomObject]$rule)
        }
      }
    }


    Context 'Egress' {

      Context 'By DestinationSecurityGroupId' {
        
        $rule =
        @{
          'ToPort'                     = 22
          'IpProtocol'                 = 'tcp'
          'FromPort'                   = 22
          'DestinationSecurityGroupId' = 'sg-12345678'
        }


        It 'Passes the rule through unchanged.' {

          [PSCustomObject](
            $rule `
            | Optimize-SecurityGroupRule -Region us-east-1 -StackName foo
          ) `
          | Should -BeLike ([PSCustomObject]$rule)
        }
      }


      Context 'By DestinationSecurityGroupName; in the default VPC' {
        
        $rule =
        @{
          'ToPort'                       = 22
          'IpProtocol'                   = 'tcp'
          'FromPort'                     = 22
          'DestinationSecurityGroupName' = 'MySecurityGroupName'
        }


        It 'Passes the rule through unchanged.' {

          [PSCustomObject](
            $rule `
            | Optimize-SecurityGroupRule -Region us-east-1 -StackName foo
          ) `
          | Should -BeLike ([PSCustomObject]$rule)
        }
        
      }
    }
  }


  Context 'Erroneous Function Calls' {

    Context 'Called without the stack name.' {
      
      It 'Throws an error.' {

        Mock Get-CfnReference
      
        { 
          @{} | Optimize-SecurityGroupRule -Region us-east-1
        } `
        | Should -Throw
      }
    }


    Context 'Called without a region.' {

      Mock Get-CfnReference
      
      It 'Throws an error.' {

        {
          @{} | Optimize-SecurityGroupRule -StackName foo
        } `
        | Should -Throw
      }
    }
  }
}
#endregion
