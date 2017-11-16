function New-CfnSecurityGroup
{
  [CmdletBinding()]
  Param
  (
    $SecurityGroup,
    $StackName,

    [Parameter(Mandatory=$true)]
    $Region
  )


  Begin {}

  Process
  {
    Write-Verbose ('Creating a New CfnSecurityGroup object from security group "{0}" associated with Cfn stack "{1}".' -f $SecurityGroup, $StackName)

    $securityGroupIngress =
      $SecurityGroup.IpPermissions `
      | ConvertTo-SecurityGroupRuleSet -Region $Region -FlowDirection 'Ingress'

    $securityGroupEgress  =
      $SecurityGroup.IpPermissionsEgress `
      | ConvertTo-SecurityGroupRuleSet -Region $Region -FlowDirection 'Egress'


    $logicalQueryParams =
    @{
      'Region'             = $Region
      'StackName'          = $StackName
      'PhysicalResourceId' = $SecurityGroup.GroupId
    }
    $sgLogicalId = Get-CfnLogicalResourceId @logicalQueryParams

    Write-Debug "SG Logical ID: $sgLogicalId"

    $sgTags = $SecurityGroup.Tags | Where-Object { $_.key -notlike 'aws:*' }

    @{
      $sgLogicalId = [PSCustomObject]@{
        'Type'       = 'AWS::EC2::SecurityGroup'
        'Properties' = [PSCustomObject]@{
          'GroupName'            = $SecurityGroup.GroupName
          'GroupDescription'     = $SecurityGroup.Description
          'SecurityGroupIngress' = @($securityGroupIngress)
          'SecurityGroupEgress'  = @($securityGroupEgress)
          'Tags'                 = $sgTags
          'VpcId'                = $SecurityGroup.VpcId
        }
      }
    }
  }

  End {}
}

