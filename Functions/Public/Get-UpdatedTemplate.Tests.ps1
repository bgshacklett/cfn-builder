#region Test Environment Setup
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut  = (
          Split-Path -Leaf $MyInvocation.MyCommand.Path
        ) `
         -replace '\.Tests\.','.'

$internalDeps = 'Get-ManagedSecurityGroup',
                'New-CfnSecurityGroup',
                'Optimize-SecurityGroupReference'

foreach ($dep in $internalDeps)
{
  $depPath = $here `
             | Split-Path -Parent `
             | Get-ChildItem -Recurse -Include ($dep + '.ps1') `
             | Select-Object -ExpandProperty FullName

  . $depPath
}

. "$here\$sut"


# Stub external dependencies
function Get-CfnTemplate { Param($Region,$StackName) }


#endregion


#region Test Logic
Describe 'Get-UpdatedTemplate' {

  $testArgs =
  @{
    'Region'      = 'us-east-1'
    'StackName'   = 'foo'
  }

  Mock Get-CfnTemplate { @{ 'Resources' = @{} } | ConvertTo-Json -Depth 2 }


  # Get-ManagedSecurityGrou needs to output a dummy PSCustomObject to ensure
  # that New-CfnSecurityGroup is called.
  Mock Get-ManagedSecurityGroup        { [PSCustomObject]@{ 'foo' = '' } }

  # Return a hashtable to ensure that OptimizeSecurityGroupReference is
  # called.
  Mock New-CfnSecurityGroup            { @{ 'foo' = '' } }

  # Pass the input through.
  Mock Optimize-SecurityGroupReference {
    @{
      'foo' = @{ 'bar' = 'foobar' }
      'bar' = @{ 'baz' = 'foobaz' }
    }
  }


  It 'Returns Resources in a Hashtable' {

    # Note: We can't use `Should -BeOfType` here, because it will
    #       automatically unwrap any collection which is returned.
    (Get-UpdatedTemplate @testArgs)['Resources'].GetType() `
    | Should -Be 'Hashtable'
  }


  Context 'The Metadata Key Does Not Exist' {

    Mock Get-CfnTemplate {

      # Generate a simple fake template.
      @{
        'AWSTemplateFormatVersion' = '2010-09-09'
        'Description'              = 'Description'
        'Parameters'               = @{ 'foo' = 'bar' }
        'Mappings'                 = @{ 'foo' = 'bar' }
        'Conditions'               = @{ 'foo' = 'bar' }
        'Transform'                = @{ 'foo' = 'bar' }
        'Resources'                = @{ 'foo' = 'bar' }
        'Outputs'                  = @{ 'foo' = 'bar' }
      } `
      | ConvertTo-Json -Depth 2
    }

    It 'Does Not Return a Metadata Section.' {

      'Metadata' | Should -Not -BeIn (Get-UpdatedTemplate @testArgs).Keys
    }

    It 'Retains the Rest of the Keys.' {

      'AWSTemplateFormatVersion' `
                    | Should -BeIn (Get-UpdatedTemplate @testArgs).Keys
      'Description' | Should -BeIn (Get-UpdatedTemplate @testArgs).Keys
      'Parameters'  | Should -BeIn (Get-UpdatedTemplate @testArgs).Keys
      'Mappings'    | Should -BeIn (Get-UpdatedTemplate @testArgs).Keys
      'Conditions'  | Should -BeIn (Get-UpdatedTemplate @testArgs).Keys
      'Transform'   | Should -BeIn (Get-UpdatedTemplate @testArgs).Keys
      'Resources'   | Should -BeIn (Get-UpdatedTemplate @testArgs).Keys
      'Outputs'     | Should -BeIn (Get-UpdatedTemplate @testArgs).Keys
    }

    It 'Retains the AWSTemplateFormatVersion Key' {

      'AWSTemplateFormatVersion' `
      | Should -BeIn (Get-UpdatedTemplate @testArgs).Keys
    }
  }
}
#endregion
