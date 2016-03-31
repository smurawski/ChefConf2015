$ModuleName = (Split-Path -leaf $MyInvocation.MyCommand.Path) -replace '\.[Tt][Ee][Ss][Tt][Ss].[Pp][Ss]1'
$TestsFolder = 1..4 |
    foreach {$Path = $MyInvocation.MyCommand.Path } {$Path = Split-Path $Path} {$Path}
$RootOfModule = Split-Path $TestsFolder
$CurrentResourceModulePath  = Join-Path $RootOfModule "DscResources/$ModuleName"

Import-Module $CurrentResourceModulePath

InModuleScope $ModuleName {
  describe 'Test-Target resource responds when' {

    context 'there is no existing app pool' {
      mock Get-AppPool -mockWith {}

      it 'returns false' {
        test-targetresource -Name 'TestAppPool' | should be $false
      }
    }


  }

  describe 'Test-Target resource responds when' {
    mock Get-AppPool -parameterFilter {$Config -eq $true -and $Name -like 'TestAppPool'} -mockWith {
      [xml]@'
<add>
  <autoStart>true</autoStart>
  <managedRuntimeVersion>v4.0</managedRuntimeVersion>
  <managedPipelineMode>Integrated</managedPipelineMode>
  <startMode>OnDemand</startMode>
  <processModel>
    <identityType>ApplicationPoolIdentity</identityType>
    <userName></userName>
    <loadUserProfile>true</loadUserProfile>
    <logonType>LogonBatch</logonType>
    <manualGroupMembership>false</manualGroupMembership>
    <idleTimeout>00:20:00</idleTimeout>
    <maxProcesses>1</maxProcesses>
    <shutdownTimeLimit>00:01:30</shutdownTimeLimit>
    <startupTimeLimit>00:01:30</startupTimeLimit>
    <pingingEnabled>true</pingingEnabled>
    <pingInterval>00:00:30</pingInterval>
    <pingResponseTime>00:01:30</pingResponseTime>
  </processModel>
  <queueLength>1000</queueLength>
  <enable32BitAppOnWin64>false</enable32BitAppOnWin64>
  <managedRuntimeLoader>webengine4.dll</managedRuntimeLoader>
  <enableConfigurationOverride>true</enableConfigurationOverride>
  <CLRConfigFile></CLRConfigFile>
  <passAnonymousToken>true</passAnonymousToken>
  <recycling>
    <logEventOnRecycle>Time, Memory, PrivateMemory</logEventOnRecycle>
    <disallowOverlappingRotation>false</disallowOverlappingRotation>
    <disallowRotationOnConfigChange>false</disallowRotationOnConfigChange>
    <periodicRestart>
      <memory>0</memory>
      <privateMemory>0</privateMemory>
      <requests>0</requests>
      <time>1.05:00:00</time>
      <schedule>
        <add>
          <value />
        </add>
      </schedule>
    </periodicRestart>
  </recycling>
  <failure>
    <loadBalancerCapabilities>HttpLevel</loadBalancerCapabilities>
    <orphanWorkerProcess>false</orphanWorkerProcess>
    <orphanActionExe></orphanActionExe>
    <orphanActionParams></orphanActionParams>
    <rapidFailProtection>true</rapidFailProtection>
    <rapidFailProtectionInterval>00:05:00</rapidFailProtectionInterval>
    <rapidFailProtectionMaxCrashes>5</rapidFailProtectionMaxCrashes>
    <autoShutdownExe></autoShutdownExe>
    <autoShutdownParams></autoShutdownParams>
  </failure>
  <cpu>
    <limit>0</limit>
    <action>NoAction</action>
    <resetInterval>00:05:00</resetInterval>
    <smpAffinitized>false</smpAffinitized>
    <smpProcessorAffinityMask>4294967295</smpProcessorAffinityMask>
    <smpProcessorAffinityMask2>4294967295</smpProcessorAffinityMask2>
  </cpu>
</add>
'@
    }
    mock Get-AppPool -parameterFilter {$Config -eq $false -and $Name -like 'TestAppPool' } -mockWith {'TestAppPool'}

    context 'there is an existing app pool and everything matches the defaults' {
      it 'returns true' {
        test-targetresource -name 'TestAppPool' | should be $true
      }
    }

    context 'there is an existing app pool and the managed runtime should be v2.0' {
      it 'returns false' {
        test-targetresource -Name 'TestAppPool' -managedRuntimeVersion "v2.0" | should be $false
      }
    }
  }
}