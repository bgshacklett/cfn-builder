
#region Test Environment Setup
$cmdPath = $MyInvocation.MyCommand.Path
$here    = Split-Path -Parent $cmdPath
$sut     = (Split-Path -Leaf $cmdPath) -replace '\.Tests\.', '.'
$deps    = 'New-Ec2SecurityGroupRule'

. "$here\$sut"

foreach ($dep in ($deps | Where-Object { $_ -as [Boolean] -eq $true }))
{
  $depPath = $here `
             | Split-Path -Parent `
             | Get-ChildItem -Recurse -Include ($dep + '.ps1') `
             | Select-Object -ExpandProperty FullName

  . $depPath
}
#endregion


#region Tests
Describe 'New-Ec2SecurityGroupRule' {

  Context 'Input allows access to an IPv4 CIDR Range' {

    It 'Returns valid output' {

      $TestContext =
      @{
        'FromPort'   = '80'
        'ToPort'     = '88'
        'IpProtocol' = 'tcp'
        'CidrIpv6'   = [PSCustomObject]@{
                         'CidrIpv6'    = '::/0'
                         'Description' = 'This is the Description'
                       }
      }

      $result = New-Ec2SecurityGroupRule @TestContext
      
      $result['FromPort']    | Should -Be '80'
      $result['ToPort']      | Should -Be '88'
      $result['IpProtocol']  | Should -Be 'tcp'
      $result['CidrIpv6']    | Should -Be '::/0'
      $result['Description'] | Should -Be 'This is the Description'
    }
  }


  Context 'Input allows access to an IPv4 CIDR Range' {

    It 'Returns valid output' {

      $TestContext =
      @{
        'FromPort'   = '80'
        'ToPort'     = '88'
        'IpProtocol' = 'tcp'
        'CidrIp'     = '0.0.0.0/0'
      }

      $result = New-Ec2SecurityGroupRule @TestContext
      
      $result['FromPort']   | Should -Be '80'
      $result['ToPort']     | Should -Be '88'
      $result['IpProtocol'] | Should -Be 'tcp'
      $result['CidrIp']     | Should -Be '0.0.0.0/0'
    }
  }


  Context 'Input allows access to a Security Group ID' {

    It 'Returns valid output' {

      $TestContext =
      @{
        'FromPort'              = '80'
        'ToPort'                = '88'
        'IpProtocol'            = 'tcp'
        'SourceSecurityGroupId' = 'sg-01234567'
      }

      $result = New-Ec2SecurityGroupRule @TestContext
      
      $result['FromPort']              | Should -Be '80'
      $result['ToPort']                | Should -Be '88'
      $result['IpProtocol']            | Should -Be 'tcp'
      $result['SourceSecurityGroupId'] | Should -Be 'sg-01234567'
    }
  }
}
#endregion
