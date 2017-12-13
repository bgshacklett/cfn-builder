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

