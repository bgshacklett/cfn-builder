function Get-UpdatedTemplate
{
  [CmdletBinding()]
  Param
  (
    $Region,
    $StackName
  )

  Begin {}

  Process
  {
    $template  = Get-CfnTemplate -Region $Region -StackName $StackName `
                 | ConvertFrom-Json

    $sgsToProcess = Get-ManagedSecurityGroup -Region $Region -StackName $StackName `
    | ForEach-Object {
      New-CfnSecurityGroup -SecurityGroup $_ -StackName $StackName -Region $Region
    }

    $optimizedSGs = $sgsToProcess | Optimize-SecurityGroupReference

    # More resources will be added here later, hence this intermediary var 
    $resources = $optimizedSGs

    # Loop through each of the updated resources and remove the matching
    # resources from the template. Then, add the updated resources.
    foreach ($key in $resources.keys)
    {
      $template.Resources.PSobject.Properties.Remove($key)
      $template.Resources `
      | Add-Member -Name $key -Value $resources.$key -MemberType NoteProperty
    }

    $template | ConvertTo-Json -Depth 99
  }

  End {}
}

