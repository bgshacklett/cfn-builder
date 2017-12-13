# Extropy
This project aims to help remediate drift (entropy) from CloudFormation
by generating updated CloudFormation template Code from existing resources.

## Installing
This module may be installed in two ways:
* In your PSModulePath (recommended for general usage)
* In a custom path (recommended for hacking on the code)

### In your PSModulePath
1. Enumerate your PSModulePath:
   ```
   $env:PSModulePath -split ';'
   ```
2. Choose which of these paths you wish to add the module to. Most likely,
   you will want the path which resides under your home directory.
3. Clone the desired tag to the chosen path. E.g.:
   ```
   git clone https://github.com/bgshacklett/extropy.git -b <Tag> ~/Documents/WindowsPowerShell/Modules/extropy
   ```
4. Import the module:
   ```
   Import-Module extropy
   ```


### In a custom location
1. Clone the repo to your preferred location:
   ```
   cd <Path>
   git clone https://github.com/bgshacklett/extropy.git
   ```
2. Check out the branch or tag you're interested in:
   ```
   git checkout <Branch|Tag>
   ```
3. Import the Module:
   ```
   Import-Module /path/to/extropy/extropy.psd1
   ```

## Usage

1. Ensure that you're logged into an AWS account on the CLI
2. Execute the Get-UpdatedTemplate function. This will return a PowerShell
   object containing the updated template.
   ```
   $template = Get-UpdatedTemplate -Region <Region> -StackName <Stack Name>
   ```
3. From here, you likely want to export the template to JSON:
   ```
   $template | ConvertTo-Json -Depth 99
   ```
   * Due to some... peculiarities with how PowerShell likes to format JSON, it
     may be adventageous to pipe the resulting JSON through your favorite
     query or formatting tool:
     ```
     $template | ConvertTo-Json -Depth 99 | jq
     ```
   * To save the file, just write it to [Out-File](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/out-file?view=powershell-5.1).
     ```
     $template `
     | ConvertTo-Json -Depth 99 `
     | jq . `
     | Out-File -Encoding utf8 -Path <path/to/file>
     ```

     _Keep in mind that PowerShell likes to put a BOM at the beginning of
     unicode files; you might want to strip that._

   * Or, if you wish to edit the file directly:
     ```
     $template | ConvertTo-Json -Depth 99 | jq . | vim -
     ```
