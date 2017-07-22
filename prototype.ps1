

function Update-SecurityGroupTemplate
{
  [CmdletBinding()]
  Param
  (
    $Path,
    $Region,
    $StackName
  )

  Begin {}

  Process
  {
    $template  = Get-Content -Path $Path | ConvertFrom-Json

    $resources = Get-ManagedSecurityGroup -Region $Region -StackName $StackName `
    | ForEach-Object {
      New-CfnSecurityGroup -SecurityGroup $_ -StackName $StackName -Region $Region
    }

    foreach ($key in $resources.keys)
    {
      $template.Resources.PSobject.Properties.Remove($key)
      $template.Resources `
      | Add-Member -Name $key -Value $resources.$key -MemberType NoteProperty
    }

    $template `
    | ConvertTo-Json -Depth 99 `
    | Out-File -Encoding utf8 -FilePath $Path
  }

  End {}
}


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


function ConvertTo-SecurityGroupRuleSet
{
  [CmdletBinding()]
  Param
  (
    [Parameter(ValueFromPipeline=$true)]
    $InputObject,
    
    [Parameter()]
    $Region,

    [Parameter(Mandatory=$true)]
    [ValidateSet('Ingress','Egress')]
    [String]$FlowDirection
  )

  Begin
  {
    Write-Verbose 'Converting an IpPermissions[Egress] collection.'
  }

  Process
  {
    Write-Verbose 'Processing an IpPermission[Egress] entity.'

    $params =
    @{
      'FromPort'      = $InputObject.FromPort
      'ToPort'        = $InputObject.ToPort
      'IpProtocol'    = $InputObject.IpProtocol
      'FlowDirection' = $FlowDirection
      'Region'        = $Region
    }

    # Aggregating all of the peer types and pass them on for rule creation
    $InputObject.IpRanges +
    $InputObject.Ipv6Ranges +
    $InputObject.PrefixListIds +
    $InputObject.UserIdGroupPairs `
    | ConvertTo-Ec2SecurityGroupRule @params
  }

  End
  {
    Write-Verbose 'Finished processing all IpPermissionEgress entities.'
  }
}


function ConvertTo-Ec2SecurityGroupRule
{
  [CmdletBinding()]
  Param
  (
    [Parameter()]
    $FromPort,

    [Parameter()]
    $ToPort,

    [Parameter()]
    $IpProtocol,

    [Parameter()]
    $FlowDirection,

    [Parameter(ValueFromPipeline=$true)]
    $InputObject,

    [Parameter(Mandatory=$true)]
    $Region
  )

  Begin
  {
    $fmtRuleContext =
@'
Received the following input...
  Port Range:   {0}-{1}
  Ip Protocol:  {2}
  Input Object: {3}
  Region:       {4}
'@

    $peerRelationship =
    @{
      'Ingress' = 'Source'
      'Egress'  = 'Destination'
    }

    $peerType =
    @{
      'String'          = 'CidrIp'
      'Ipv6Range'       = 'CidrIpv6'
      'PrefixListId'    = 'DestinationPrefixListId'
      'UserIdGroupPair' = "$($peerRelationship.$FlowDirection)SecurityGroupId"
    }
  }

  Process
  {
    Write-Verbose 'Converting an IpPermission entry to an EC2 SG Rule'

    Write-Debug ($fmtRuleContext -f $FromPort,
                                    $ToPort,
                                    $IpProtocol,
                                    $InputObject,
                                    $Region)

    $ruleProperties =
    @{
      'FromPort'   = $FromPort
      'ToPort'     = $ToPort
      'IpProtocol' = $IpProtocol
    }

    $ruleType = $InputObject.GetType().Name

    Write-Verbose ('The peer type is: "{0}"' -f $peerType.$ruleType)

    # UserIdGroupPairs need to be treated differently because they require
    # further discovery
    If ($ruleType -eq 'UserIdGroupPair')
    {
      Write-Verbose 'The peer is a reference to another Security Group'
      # If this is a Security Group in the same Template, we'll want to
      # replace the hard coded ID with a "Ref" function to the logical ID of
      # the security group. If not, we can leave the ID in place.

      $uidGroupPairConversionArgs =
      @{
        'GroupId'   = $InputObject.GroupId
        'Region'    = $Region
        'StackName' = $StackName
      }
      $peer = ConvertFrom-UserIdGroupPair @uidGroupPairConversionArgs
    }
    else
    {
      $peer = $InputObject
    }

    $ruleProperties.Add($peerType.$ruleType, $peer)

    New-Ec2SecurityGroupRule @ruleProperties
  }

  End
  {
    Write-Verbose 'Finished building EC2 Security Group Rules.'
  }
}


function ConvertFrom-UserIdGroupPair
{
  [CmdletBinding()]
  Param
  (
    $GroupId,
    $Region,
    $StackName
  )

  Begin {}

  Process
  {
    Write-Debug ('Searching for the SG {0} in the Stack "{1}".' `
                   -f $GroupId, $StackName)

    $refQueryParams =
    @{
      'Region'             = $Region
      'StackName'          = $StackName
      'PhysicalResourceId' = $GroupId
    }
    # Return either a 'Ref' or the Group ID if the Ref is null.
    ((Get-CfnReference @refQueryParams),$GroupId -ne $null)[0]
  }

  End {}
}


function Get-CfnReference
{
  [CmdletBinding()]
  Param
  (
    $PhysicalResourceId,
    $StackName,

    [Parameter(Mandatory=$true)]
    $Region
  )

  Begin {} 

  Process
  {
    $resourceQueryParams =
    @{
      'Region'             = $Region
      'StackName'          = $StackName
      'PhysicalResourceId' = $PhysicalResourceId
    }
    $logicalResourceId = Get-CfnLogicalResourceId @resourceQueryParams


    # Return a 'Ref' hashtable, but only if it's not null
    @{ 'Ref' = $logicalResourceId } | Where-Object { $_.Ref }
  }

  End {}
}


function Get-CfnLogicalResourceId
{
  [CmdletBinding()]
  Param
  (
    $PhysicalResourceId,
    $StackName,

    [Parameter(Mandatory=$true)]
    $Region
  )

  Begin
  {
    Write-Verbose ('Getting the Cfn Logical Resource ID of "{0}" in stack "{1}".' -f $PhysicalResourceId, $StackName)
  }

  Process
  {
    Get-CfnStackResources -Region $Region -StackName $StackName `
    | Where-Object { $_.PhysicalResourceId -eq $PhysicalResourceId } `
    | Select-Object -ExpandProperty LogicalResourceId
  }

  End {}
}


function New-Ec2SecurityGroupRule
{
  [CmdletBinding()]
  Param
  (
    [Parameter(ParameterSetName = 'CidrIp')]
    [Parameter(ParameterSetName = 'CidrIpv6')]
    [Parameter(ParameterSetName = 'DestinationPrefixListId')]
    [Parameter(ParameterSetName = 'SourceSecurityGroupId')]
    [Parameter(ParameterSetName = 'DestinationSecurityGroupId')]
    $FromPort,

    [Parameter(ParameterSetName = 'CidrIp')]
    [Parameter(ParameterSetName = 'CidrIpv6')]
    [Parameter(ParameterSetName = 'DestinationPrefixListId')]
    [Parameter(ParameterSetName = 'SourceSecurityGroupId')]
    [Parameter(ParameterSetName = 'DestinationSecurityGroupId')]
    $ToPort,

    [Parameter(ParameterSetName = 'CidrIp')]
    [Parameter(ParameterSetName = 'CidrIpv6')]
    [Parameter(ParameterSetName = 'DestinationPrefixListId')]
    [Parameter(ParameterSetName = 'SourceSecurityGroupId')]
    [Parameter(ParameterSetName = 'DestinationSecurityGroupId')]
    $IpProtocol,

    [Parameter(ParameterSetName = 'CidrIp')]
    $CidrIp,

    [Parameter(ParameterSetName = 'CidrIpv6')]
    $CidrIpv6,

    [Parameter(ParameterSetName = 'DestinationPrefixListId')]
    $DestinationPrefixListId,

    [Parameter(ParameterSetName = 'DestinationSecurityGroupId')]
    $DestinationSecurityGroupId,

    [Parameter(ParameterSetName = 'SourceSecurityGroupId')]
    $SourceSecurityGroupId
  )

  Begin { }

  Process
  {
    Write-Verbose 'Building a new EC2 Security Group Rule'

    # The peer type is decided based on which peer parameter is passed in.
    $peerType  = $PsCmdlet.ParameterSetName

    # We get the peer value from the value of the afore-mentioned parameter.
    $peerValue = $PSBoundParameters.$peerType

    @{
      'IpProtocol' = $IpProtocol
      'FromPort'   = $FromPort
      'ToPort'     = $ToPort
      "$peerType"  = $peerValue
    }
  }

  End {}
}

function Get-ManagedSecurityGroup
{
  [CmdletBinding()]
  Param
  (
    $Region,
    $StackName
  )


  Begin
  {
    Write-Verbose ('Getting managed Security Groups from the stack "{0}"' -f $StackName)
  }

  Process
  {
    Get-CfnStackResources -Region $Region -StackName $StackName `
    | Where-Object {
      $_.ResourceType -eq 'AWS::EC2::SecurityGroup'
    } `
    | Select-Object -ExpandProperty PhysicalResourceId `
    | Get-Ec2SecurityGroup -Region $Region
  }

  End {}
}
