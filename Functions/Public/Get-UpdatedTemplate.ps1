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
    $origMetaData      = $origTemplate.MetaData
    $origParameters    = $origTemplate.Parameters
    $origMappings      = $origTemplate.Mappings
    $origConditions    = $origTemplate.Conditions
    $origTransform     = $origTemplate.Transform
    $origResources     = $origTemplate.Resources
    $origOutputs       = $origTemplate.Outputs
  }

  Process
  {
    $optimizedSGs = (
                      Get-ManagedSecurityGroup @stackContext `
                      | New-CfnSecurityGroup @stackContext `
                      | ForEach-Object { $res  = @{} } `
                                       { $res += $_  } `
                                       { $res        }
                    ).GetEnumerator() `
                    | Optimize-SecurityGroupReference @stackContext

    # More resources will be added here later, hence this intermediary var 
    # e.g.: $optimizedresources = $optimizedSGs + $optimizedX...
    # ...where $optimized[X|Y|Z|...] is a hashtable of optimized resources
    $optimizedResources = $optimizedSGs


    # Get a hashtable of resources from the original template which do not
    # exist in the hashtable of optimized resources.
    #$diffResources = $templateResources.psobject.Properties `
    #                 | Where-Object { $_.Name -notin $optimizedResources.Keys } `
    #                 | ForEach-Object { $res  = @{}                     } `
    #                                  { $res += @{ $_.Name = $_.Value } }
    #                                  { $res                            }

    $diffResources = @{}

    @{
      'AWSTemplateFormatVersion' = $origFormatVersion
      'Description'              = $origDescription
      'MetaData'                 = $origMetaData
      'Parameters'               = $origParameters
      'Mappings'                 = $origMappings
      'Conditions'               = $origConditions
      'Transform'                = $origTransform
      'Resources'                = $optimizedResources
      'Outputs'                  = $origOutputs
    }
  }

  End {}
}

