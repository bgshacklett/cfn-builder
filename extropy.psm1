#Get public and private function definition files.
$Public = Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 `
                        -Exclude *.Tests.ps1 `
                        -ErrorAction SilentlyContinue
$Private = Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 `
                         -Exclude *.Tests.ps1 `
                         -ErrorAction SilentlyContinue

#Dot source the files
Foreach($import in @($Private))
{
  Try
  {
      . $import.fullname
  }
  Catch
  {
      Write-Error -Message "Failed to import function $($import.fullname): $_"
  }
}

Foreach($import in @($Public))
{
  Try
  {
      . $import.fullname
      Export-ModuleMember -Function $import.Basename
  }
  Catch
  {
      Write-Error -Message "Failed to import function $($import.fullname): $_"
  }
}



