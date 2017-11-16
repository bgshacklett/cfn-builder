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

    $resources = Get-ManagedSecurityGroup -Region $Region -StackName $StackName `
    | ForEach-Object {
      New-CfnSecurityGroup -SecurityGroup $_ -StackName $StackName -Region $Region
    }

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

