
powershell_script "Configure LCM" do
  code <<-EOH
    Configuration ConfigLCM
    {
        Node "localhost"
        {
            LocalConfigurationManager
            {
                ConfigurationMode = "ApplyOnly"
                RebootNodeIfNeeded = $false
                RefreshMode = 'PUSH'
            }
        }
    }

    ConfigLCM -OutputPath "#{Chef::Config[:file_cache_path]}\\DSC_LCM"

    Set-DscLocalConfigurationManager -Path "#{Chef::Config[:file_cache_path]}\\DSC_LCM"
  EOH
  only_if <<-EOH
    $LCM = (Get-DscLocalConfigurationManager)
    $LCM.ConfigurationMode -notlike "ApplyOnly" -or $LCM.RefreshMode -notlike 'PUSH'
  EOH
end
