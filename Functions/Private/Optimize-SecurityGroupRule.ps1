function Optimize-SecurityGroupRule
{
  [CmdletBinding()]
  Param
  (
    [Parameter(ValueFromPipeline = $true, Mandatory=$true)]
    $InputObject,

    [Parameter(Mandatory = $true)]
    $Region,

    [Parameter(Mandatory = $true)]
    $StackName
  )

  Begin
  {
    $sourceDestinationKeys = 'CidrIp',
                             'CidrIpv6',
                             'SourceSecurityGroupName',
                             'DestinationSecurityGroupName',
                             'SourceSecurityGroupId',
                             'DestinationSecurityGroupId',
                             'DestinationPrefixListId'

    $fmtInvalidType   = 'The type "{0}" is unknown and cannot be processed.'

    $fmtSrcDestList  =
    (
      'Sources/Destinations Encountered:',
      '{0}'
    ) -join '`n'

    $fmtSourceDestLengthInvalid =
    (
      'An unexpected number of sources or destinations was encountered.',
      'Expected: 1.',
      'Actual: {0}'
    ) -join '`n'
  }

  Process
  {
    $srcDestSpec =
    (
      $InputObject.GetEnumerator() `
      | Where-Object {
                       ($_.Key) -in $sourceDestinationKeys
                     }
    )

    Write-Debug (
                  $fmtSrcDestList -f
                  ($srcDestSpec | ForEach-Object { $_ })
                )
    # We expect the length of the above to always be one based on the
    # following docs:
    # * https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-security-group-ingress.html
    # * https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-security-group-egress.html
    if (($length = $srcDestSpec.Length) -and ($length -ne 1))
    {
      throw ($fmtSourceDestLengthInvalid -f $length)
    }


    $protoSpec = $InputObject.GetEnumerator() `
                | Where-Object {
                                 ($_.Key) -and
                                 (
                                   $_.Key -notin $sourceDestinationKeys
                                 )
                               }


    $referenceQueryParams =
    @{
      'Region'             = $Region
      'StackName'          = $StackName
      'PhysicalResourceId' = $srcDestSpec.Value
    }
    $ref = Get-CfnReference @referenceQueryParams

    # Return the union of the protocol and the source/destination specs.
    (
      $protoSpec | ForEach-Object { $res = @{} } `
                                  { $res += @{ $_.Key = $_.Value } } `
                                  { $res }
    ) +
    @{
      $srcDestSpec.Key = (
                           $ref,
                           $srcDestSpec.Value `
                           -ne $null
                         )[0]
    }
  }

  End {}
}
