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
  Port Range:    {0}-{1}
  Ip Protocol:   {2}
  Input Object:  {3}
  Region:        {4}
  FlowDirection: {5}
  Rule Type:     {6}
'@

    $peerRelationship =
    @{
      'Ingress' = 'Source'
      'Egress'  = 'Destination'
    }

    $peerTypeMap =
    @{
      'IpRange'         = 'CidrIp'
      'Ipv6Range'       = 'CidrIpv6'
      'PrefixListId'    = 'DestinationPrefixListId'
      'UserIdGroupPair' = "$($peerRelationship.$FlowDirection)SecurityGroupId"
    }
  }

  Process
  {
    $ruleType = $InputObject.GetType().Name

    Write-Verbose 'Converting an IpPermission entry to an EC2 SG Rule'

    Write-Debug ($fmtRuleContext -f $FromPort,
                                    $ToPort,
                                    $IpProtocol,
                                    $InputObject,
                                    $Region,
                                    $FlowDirection,
                                    $ruleType)

    $ruleProperties =
    @{
      'FromPort'   = $FromPort
      'ToPort'     = $ToPort
      'IpProtocol' = $IpProtocol
    }

    Write-Verbose ('The peer type is: "{0}"' -f $peerTypeMap.$ruleType)

    # UserIdGroupPairs need to be treated differently because they require
    # further discovery
    If ($ruleType -eq 'UserIdGroupPair')
    {
      Write-Verbose 'The peer is a reference to another Security Group'
      # If this is a Security Group in the same Template, we'll set the
      # GroupId as the peer. We'll update references later so we can account
      # for circular dependencies and break out SecurityGroup[Ingress|Egress]
      # resources..

      $peer = $InputObject.GroupId
    }
    else
    {
      $peer = $InputObject
    }

    # !@#%*^&
    $ruleProperties.Add($peerTypeMap.$ruleType, $peer)

    New-Ec2SecurityGroupRule @ruleProperties
  }

  End
  {
    Write-Verbose 'Finished building EC2 Security Group Rules.'
  }
}

