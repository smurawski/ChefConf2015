$ModuleName = (Split-Path -leaf $MyInvocation.MyCommand.Path) -replace '\.[Tt][Ee][Ss][Tt][Ss].[Pp][Ss]1'
$TestsFolder = 1..4 |
    foreach {$Path = $MyInvocation.MyCommand.Path } {$Path = Split-Path $Path} {$Path}
$RootOfModule = Split-Path $TestsFolder
$CurrentResourceModulePath  = Join-Path $RootOfModule "DscResources/$ModuleName"

Import-Module $CurrentResourceModulePath

InModuleScope $ModuleName {
  describe 'Test-TargetResource' {
    $TestTargetResourceParameters = @{
      WebsiteName = 'Default'
      IPAddress = '*'
      Port = 80
      Protocol = 'http'
    }

    context 'When a site exists but the binding does not exist' {
      mock 'Get-MatchingWebBinding' -mockwith {}
      mock 'Get-Website' -mockwith {[pscustomobject]@{name = 'Default'}}

      it 'returns false' {
        Test-TargetResource @TestTargetResourceParameters | should be $false
      }
    }
    context 'When does not exist' {
      mock 'Get-MatchingWebBinding' -mockwith {}
      mock 'Get-Website' -mockwith {}

      it 'throws an exception' {
        {Test-TargetResource @TestTargetResourceParameters }| should throw
      }
    }
    context 'When a binding exists' {
      mock 'Get-MatchingWebBinding' -mockwith {
        [pscustomobject]@{
          Name = 'Default'
          IPAddress = '*'
          Port = 80
          Protocol = 'http'
          CertificateThumbprint = ''
          CertificateStoreName = ''
          Hostname = ''
        }
      }
      mock 'Get-Website' -mockwith {}

      it 'returns $true' {
        Test-TargetResource @TestTargetResourceParameters | should be $true
      }
    }

  }
}