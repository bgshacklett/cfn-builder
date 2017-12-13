function Optimize-SecurityGroupReference
{
  [CmdletBinding()]
  Param
  (
    [Parameter(ValueFromPipeline = $true)]
    $InputObject,

    [Parameter(Mandatory = $true)]
    $Region,

    [Parameter(Mandatory = $true)]
    $StackName
  )

  Begin {}

  Process
  {
    Write-Verbose ('InputObject: ' + $InputObject)

    $sgIngress     = $InputObject.Value['Properties']['SecurityGroupIngress']
    $sgEgress      = $InputObject.Value['Properties']['SecurityGroupEgress']
    $sgTags        = $InputObject.Value['Properties']['Tags']
    $sgDescription = $InputObject.Value['Properties']['GroupDescription']
    $sgVpcId       = $InputObject.Value['Properties']['VpcId']

    $sgContext =
    @{
      'Region'    = $Region
      'StackName' = $StackName
    }

    $optimizedIngress = $sgIngress `
                        | Where-Object { $_ } `
                        | Optimize-SecurityGroupRule @sgContext

    $optimizedEgress  = $sgEgress `
                        | Where-Object { $_ } `
                        | Optimize-SecurityGroupRule @sgContext

    $optimizedVpcId   = (
                          (
                            Get-CfnReference @sgContext `
                                             -PhysicalresourceId $sgVpcId
                          ),
                          $sgVpcId `
                          -ne $null
                        )[0] 

    @{
      $InputObject.Key = @{
        'Type'       = 'AWS::EC2::SecurityGroup'
        'Properties' = @{
          'SecurityGroupIngress' = $optimizedIngress
          'SecurityGroupEgress'  = $optimizedEgress
          'Tags'                 = $sgTags
          'GroupDescription'     = $sgDescription
          'VpcId'                = $optimizedVpcId
        }
      }
    }
  }

  End {}
}
