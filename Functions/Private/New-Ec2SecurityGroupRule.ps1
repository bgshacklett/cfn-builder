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
    [Amazon.EC2.Model.Ipv6Range]
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

    # We'll get the input dynamically based on the parameter set name.
    $peerValue = $PSBoundParameters.$peerType

    # If we get a simple value, such as a string or an int, we need to wrap it
    # in a Hashtable to allow combining it with the inputs we will be passing
    # through.
    if ($peerValue.Gettype() -in 'String','int')
    {
      # Wrap the value in a simple hashtable.
      $peerHash = @{ $peerType = $peerValue }
    }
    else
    {
      # Reduce the properties of peerValue to a Hashtable
      $peerHash = $peerValue.psobject.Properties `
                  | ForEach-Object { $result = @{} } `
                                   { $result += @{ $_.Name = $_.Value } } `
                                   { $result }
    }

    @{
      'IpProtocol' = $IpProtocol
      'FromPort'   = $FromPort
      'ToPort'     = $ToPort
    } +
    $peerHash
  }

  End {}
}

