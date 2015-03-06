include_recipe 'basic_website::lcm_setup_dsc_script'


dsc_script 'Setup IIS' do
  imports 'ChefConfSamples'
  code <<-SETUPIIS
    windowsfeature 'iis'
    {
      Name = 'web-server'
    }

    service 'w3svc'
    {
      Name = 'w3svc'
      StartupType = 'Automatic'
      State = 'Running'
      DependsOn = '[windowsfeature]iis'
    }

    WebSite 'Shutdown Default Website'
    {
      Name = 'Default Web Site'
      State = 'Stopped'
      PhysicalPath = 'C:\\inetpub\\wwwroot\\'
      DependsOn = '[windowsfeature]iis'
    }
  SETUPIIS
end

node['iis_demo']['sites'].each do |site_name, site_data|
  site_dir = "#{ENV['SYSTEMDRIVE']}\\inetpub\\wwwroot\\#{site_name}"
  dsc_script "Configure Site #{site_name}" do
    imports 'ChefConfSamples'
    code <<-SITESDSC
      $SiteDir = '#{site_dir}'
      file "#{site_name}Directory"
      {
        DestinationPath = $SiteDir
        Type = 'Directory'
      }
      WebAppPool "#{site_name}AppPool"
      {
        Name = "#{site_name}"
      }
      WebSite "#{site_name}WebSite"
      {
        Name = '#{site_name}'
        ApplicationPool = "#{site_name}"
        PhysicalPath = $SiteDir
        DependsOn = '[WebAppPool]#{site_name}AppPool', '[file]#{site_name}Directory'
      }
      WebBinding "#{site_name}Binding"
      {
        WebsiteName = '#{site_name}'
        IPAddress = '*'
        Port = #{site_data['port']}
        Protocol = 'http'
      }
    SITESDSC
  end

  template "#{site_dir}\\Default.htm" do
      source "Default.htm.erb"
      rights :read, "Everyone"
      variables(
          :site_name => site_name,
          :port => site_data['port']
          )
  end
end