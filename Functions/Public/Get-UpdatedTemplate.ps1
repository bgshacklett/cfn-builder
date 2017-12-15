function Get-UpdatedTemplate
{
  [CmdletBinding()]
  Param
  (
    $Region,
    $StackName
  )

  Begin
  {
    $stackContext =
    @{
      'Region'    = $Region
      'StackName' = $StackName
    }

    $origTemplate      = Get-CfnTemplate @stackContext | ConvertFrom-Json
    $origFormatVersion = $origTemplate.AWSTemplateFormatVersion
    $origDescription   = $origTemplate.Description
    $origMetadata      = $origTemplate.MetaData
    $origParameters    = $origTemplate.Parameters
    $origMappings      = $origTemplate.Mappings
    $origConditions    = $origTemplate.Conditions
    $origTransform     = $origTemplate.Transform
    $origResources     = $origTemplate.Resources
    $origOutputs       = $origTemplate.Outputs
  }

  Process
  {
    # TODO: This is a bit wonky; it should be doable with only one reduction.
    $optimizedSGs = (
                      Get-ManagedSecurityGroup @stackContext `
                      | New-CfnSecurityGroup @stackContext `
                      | ForEach-Object { $res  = @{} } `
                                       { $res += $_  } `
                                       { $res        }
                    ).GetEnumerator() `
                    | Optimize-SecurityGroupReference @stackContext `
                    | ForEach-Object { $res  = @{} } `
                                     { $res += $_  } `
                                     { $res        }

    # Get a hashtable of resources from the original template which do not
    # exist in the hashtable of optimized resources.
    $diffResources = $origResources.psobject.Properties `
                     | Where-Object { $_.Name -notin $optimizedSGs.Keys } `
                     | ForEach-Object { $res  = @{}                     } `
                                      { $res += @{ $_.Name = $_.Value } } `
                                      { $res                            }


    # Build each section as a hashtable which is omitted if it's null.
    @{
      'AWSTemplateFormatVersion' = $origFormatVersion
    },
    @{
      'Description'              = $origDescription
    },
    @{
      'Metadata'                 = $origMetadata
    },
    @{
      'Parameters'               = $origParameters
    },
    @{
      'Mappings'                 = $origMappings
    },
    @{
      'Conditions'               = $origConditions
    },
    @{
      'Transform'                = $origTransform
    },
    @{
      'Resources'                = $optimizedSGs +
                                   $diffResources
    },
    @{
      'Outputs'                  = $origOutputs
    } `
    | Where-Object   { $_.Values } `
    | ForEach-Object { $res  = @{} } `
                     { $res += $_  } `
                     { $res        }
  }

  End {}
}

