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
    $sgIngress       = $InputObject['Properties']['SecurityGroupIngress']
    $sgEgress        = $InputObject['Properties']['SecurityGroupEgress']
    $sgTags          = $InputObject['Properties']['Tags']
    $sgDescription   = $InputObject['Properties']['GroupDescription']
    $sgVpcId         = $InputObject['Properties']['VpcId']

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
      'Type'       = 'AWS::EC2::SecurityGroup'
      'Properties' =
      @{
        'SecurityGroupIngress' = $optimizedIngress
        'SecurityGroupEgress'  = $optimizedEgress
        'Tags'                 = $InputObject['Properties']['Tags']
        'GroupDescription'     = $InputObject['Properties']['GroupDescription']
        'VpcId'                = $optimizedVpcId
      }
    }
  }

  End {}
}
