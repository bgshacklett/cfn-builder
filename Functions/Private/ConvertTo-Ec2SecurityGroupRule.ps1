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

