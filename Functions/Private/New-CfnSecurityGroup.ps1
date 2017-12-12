function New-CfnSecurityGroup
{
  [CmdletBinding()]
  Param
  (
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    $InputObject,
    $StackName,

    [Parameter(Mandatory=$true)]
    $Region
  )


  Begin {}

  Process
  {
    Write-Verbose ('Creating a New CfnSecurityGroup object from security group "{0}" associated with Cfn stack "{1}".' -f $InputObject, $StackName)

    $securityGroupIngress =
      $InputObject.IpPermissions `
      | ConvertTo-SecurityGroupRuleSet -Region $Region -FlowDirection 'Ingress'

    $securityGroupEgress  =
      $InputObject.IpPermissionsEgress `
      | ConvertTo-SecurityGroupRuleSet -Region $Region -FlowDirection 'Egress'


    $logicalQueryParams =
    @{
      'Region'             = $Region
      'StackName'          = $StackName
      'PhysicalResourceId' = $InputObject.GroupId
    }
    $sgLogicalId = Get-CfnLogicalResourceId @logicalQueryParams

    Write-Debug "SG Logical ID: $sgLogicalId"

    $sgTags = $InputObject.Tags | Where-Object { $_.key -notlike 'aws:*' }

    @{
      $sgLogicalId = @{
        'Type'       = 'AWS::EC2::SecurityGroup'
        'Properties' = @{
          'GroupName'            = $InputObject.GroupName
          'GroupDescription'     = $InputObject.Description
          'SecurityGroupIngress' = @($securityGroupIngress)
          'SecurityGroupEgress'  = @($securityGroupEgress)
          'Tags'                 = $sgTags
          'VpcId'                = $InputObject.VpcId
        }
      }
    }
  }

  End {}
}

