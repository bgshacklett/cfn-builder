

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
    Get-ManagedSecurityGroup -Region $Region -StackName $StackName `
    | ForEach-Object {
      New-CfnSecurityGroup -SecurityGroup $_ -StackName $StackName -Region $Region
    } `
    | ForEach-Object {
      Set-TemplateSecurityGroup -Path $Path
    }
  }

  End {}
}


function Set-TemplateSecurityGroup
{
  throw [System.NotImplementedException]
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

    $securityGroupIngress = $SecurityGroup.IpPermissions `
                            | ConvertTo-SecurityGroupIngress -Region $Region

    $securityGroupEgress  = $SecurityGroup.IpPermissionsEgress `
                            | ConvertTo-SecurityGroupEgress -Region $Region


    
    [PSCustomObject]@{
      'GroupName'            = $SecurityGroup.GroupName
      'GroupDescription'     = $SecurityGroup.Description
      'SecurityGroupIngress' = @($securityGroupIngress)
      'SecurityGroupEgress'  = @($securityGroupEgress)
      'Tags'                 = $SecurityGroup.Tags
      'VpcId'                = $SecurityGroup.VpcId
    }
  }

  End {}
}


function ConvertTo-SecurityGroupIngress
{
  [CmdletBinding()]
  Param
  (
    [Parameter(ValueFromPipeline=$true)]
    $InputObject,
    
    [Parameter(Mandatory=$true)]
    $Region
  )

  Begin
  {
    Write-Verbose 'Converting an IpPermissions collection to the SecurityGroupIngress format.'
  }

  Process
  {
    Write-Verbose 'Processing an IpPermission entity'

    $params =
    @{
      'FromPort'   = $InputObject.FromPort
      'ToPort'     = $InputObject.ToPort
      'IpProtocol' = $InputObject.IpProtocol
      'Region'     = $Region
    }

    $InputObject.IpRanges +
    $InputObject.Ipv6Ranges +
    $InputObject.UserIdGroupPairs `
    | ConvertTo-Ec2SecurityGroupRule @params
  }

  End
  {
    Write-Verbose 'Finished processing the IpPermissions collection.'
  }
}



function ConvertTo-SecurityGroupEgress
{
  [CmdletBinding()]
  Param
  (
    [Parameter(ValueFromPipeline=$true)]
    $InputObject,
    
    [Parameter()]
    $Region
  )

  Begin
  {
    Write-Verbose 'Converting an IpPermissionsEgress collection to the SecurityGroupEgress format.'
  }

  Process
  {
    Write-Verbose 'Processing an IpPermissionEgress entity.'

    $params =
    @{
      'FromPort'   = $InputObject.FromPort
      'ToPort'     = $InputObject.ToPort
      'IpProtocol' = $InputObject.IpProtocol
      'Region'     = $Region
    }

    # Aggregating all of the source types and pass them on for rule creation
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

    [Parameter(ValueFromPipeline=$true)]
    $InputObject,

    [Parameter(Mandatory=$true)]
    $Region
  )

  Begin
  {
$fmtIngressRuleContext =
@'
Received the following input...
  Port Range:   {0}-{1}
  Ip Protocol:  {2}
  Input Object: {3}
  Region:       {4}
'@

$fmtIngressRuleDetails =
@'
Creating a new Ingress Rule...
  Region:              {0}
  StackName:           {1}
  InputObject.GroupId: {2}
  Rule Source:         {3}
'@

  }

  Process
  {
    Write-Verbose 'Converting an IpPermission entry to an EC2 Security Group Rule'

    Write-Debug ($fmtIngressRuleContext -f $FromPort, $ToPort, $IpProtocol, $InputObject, $Region)

    $ruleType = $InputObject.GetType().Name

    $ingressRuleParams =
    @{
      'FromPort'   = $FromPort
      'ToPort'     = $ToPort
      'IpProtocol' = $IpProtocol
    }

    Switch ($ruleType)
    {
      'String'
      {
        Write-Verbose 'The source is an IPv4 IP Address Range'
        $ingressRuleParams.Add('CidrIp', $InputObject)

        New-Ec2SecurityGroupRule @ingressRuleParams
      }

      'Ipv6Range'
      {
        Write-Verbose 'The source is an IPv6 IP Address Range'
        $ingressRuleParams.Add('CidrIpv6', $InputObject)

        New-Ec2SecurityGroupRule @ingressRuleParams
      }

      'PrefixListId'
      {
        Write-Verbose 'The source is a PrefixList Id.'
        Write-Verbose 'This is not supported for Ingress Rules'

        throw ('This rule specifies a Prefix List ({0}) which is not supported for Ingress rules') -f $InputObject
      }

      'UserIdGroupPair'
      {
        Write-Verbose 'The source is a reference to another Security Group'
        # If this is a Security Group in the same Template, we'll want to
        # replace the hard coded ID with a "Ref" function to the logical ID of
        # the security group. If not, we can leave the ID in place.

        Write-Debug ('Searching for the SG {0} in the Stack "{1}".' `
                       -f $InputObject.GroupId, $StackName)
        try
        {
          $resourceQueryParams =
          @{
            'Region'             = $Region
            'StackName'          = $StackName
            'PhysicalResourceId' = $InputObject.GroupId
          }
          $logicalResourceId = Get-CfnLogicalResourceId @resourceQueryParams

          $ref = @{ 'Ref' = $logicalResourceId }
        }
        catch
        {
          Write-Verbose ('Unable to locate SG {0} in stack {1}' `
                         -f $InputObject.GroupId, $StackName)

          throw $_
        }


        $ruleSource = $null
        if ([bool]$ref)
        {
          Write-Verbose ('A reference was discovered. SG {0} has a logical resource id of {1} in stack {2}' -f $InputObject.GroupId, $logicalResourceId, $StackName)
          $ruleSource = $ref
        }
        else
        {
          $ruleSource = $InputObject.GroupId
        }

        $ingressRuleParams.Add('SourceSecurityGroupId', $ruleSource)

        Write-Debug ($fmtIngressRuleDetails -f $Region,
                                               $StackName,
                                               $InputObject.GroupId,
                                               $ruleSource)

        New-Ec2SecurityGroupRule @ingressRuleParams
      }

      default
      {
        throw 'Unknown Security Rule Source Type: "{0}"' -f $ruleType
      }
    }
  }

  End
  {
    Write-Verbose 'Finished building EC2 Security Group Rules.'
  }
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
    [Parameter(ParameterSetName = 'SourceSecurityGroupId')]
    $FromPort,

    [Parameter(ParameterSetName = 'CidrIp')]
    [Parameter(ParameterSetName = 'CidrIpv6')]
    [Parameter(ParameterSetName = 'SourceSecurityGroupId')]
    $ToPort,

    [Parameter(ParameterSetName = 'CidrIp')]
    [Parameter(ParameterSetName = 'CidrIpv6')]
    [Parameter(ParameterSetName = 'SourceSecurityGroupId')]
    $IpProtocol,

    [Parameter(ParameterSetName = 'CidrIp')]
    $CidrIp,

    [Parameter(ParameterSetName = 'CidrIpv6')]
    $CidrIpv6,

    [Parameter(ParameterSetName = 'SourceSecurityGroupId')]
    $SourceSecurityGroupId
  )

  Begin { }

  Process
  {
    Write-Verbose 'Building a new EC2 Security Group Rule'

    Switch ($PsCmdlet.ParameterSetName)
    {
      'CidrIp'
      {
        @{
          'IpProtocol' = $IpProtocol
          'FromPort'   = $FromPort
          'ToPort'     = $ToPort
          'CidrIp'     = $CidrIp
        }
      }

      'CidrIpv6'
      {
        @{
          'IpProtocol' = $IpProtocol
          'FromPort'   = $FromPort
          'ToPort'     = $ToPort
          'CidrIpv6'   = $CidrIpv6
        }
      }

      'SourceSecurityGroupId'
      {
        @{
          'IpProtocol'            = $IpProtocol
          'FromPort'              = $FromPort
          'ToPort'                = $ToPort
          'SourceSecurityGroupId' = $SourceSecurityGroupId
        }
      }

      default
      {
        throw ('Uknown Parameter Set Name "{0}"') -f $PsCmdlet.ParameterSetName
      }
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
    }
  }

  End {}
}
