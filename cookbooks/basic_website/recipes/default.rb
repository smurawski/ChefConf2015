#
# Cookbook Name:: basic_website
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

powershell_script 'Install IIS' do
  code 'add-windowsfeature Web-Server'
  action :run
end

service 'w3svc' do
  action [:enable, :start]
end

powershell_script 'disable default site' do
  code 'get-website "Default Web Site*" | where {$_.state -ne "Stopped"} | Stop-Website'
end

node['iis_demo']['sites'].each do |site_name, site_data|
  site_dir = "#{ENV['SYSTEMDRIVE']}\\inetpub\\wwwroot\\#{site_name}"
  directory site_dir

  powershell_script "create app pool for #{site_name}" do
    code "New-WebAppPool #{site_name}"
    not_if "C:\\Windows\\System32\\inetsrv\\appcmd.exe list apppool #{site_name}"
  end

  powershell_script "new website for #{site_name}" do
    code <<-EOH
            Import-Module WebAdministration
            if (-not(test-path IIS:\\Sites\\#{site_name})){
              $NewWebsiteParams = @{Name= '#{site_name}';Port= #{site_data['port']};PhysicalPath= '#{site_dir}';ApplicationPool= '#{site_name}'}
              New-Website @NewWebsiteParams
            }
            elseif ((Get-WebBinding -Name #{site_name}).bindingInformation -ne '*:#{site_data['port']}:') {
              $CurrentBinding = (Get-WebBinding -Name #{site_name}).bindingInformation
              $BindingParameters = @{Name= '#{site_name}';Binding= $CurrentBinding;PropertyName= 'Port';Value = #{site_data['port']} }
              Set-WebBinding @BindingParameters
            }
            Get-Website -Name #{site_name} | Where {$_.state -like 'Stopped'} | Start-Website
        EOH
  end

  template "#{site_dir}\\Default.htm" do
    source 'Default.htm.erb'
    rights :read, 'Everyone'
    variables(
      site_name: site_name,
      port: site_data['port']
    )
    notifies :restart, 'service[w3svc]'
  end
end
