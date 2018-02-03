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
    $InputObject.Ipv4Ranges +
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

