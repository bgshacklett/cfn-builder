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
    $template  = Get-Content -Path $Path | ConvertFrom-Json

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

    $template `
    | ConvertTo-Json -Depth 99 `
    | Out-File -Encoding utf8 -FilePath $Path
  }

  End {}
}

