include_recipe 'demo::lcm_setup_dsc_resource'

directory "#{ENV['ProgramW6432']}/WindowsPowerShell/Modules/ChefConfSamples"

remote_directory "#{ENV['ProgramW6432']}/WindowsPowerShell/Modules/ChefConfSamples" do
  source 'ChefConfSamples'
  action :create
end


dsc_resource 'Install IIS' do
  resource :windowsfeature
  property :name,  'web-server'
end

service 'w3svc' do
  action [:enable, :start]
end

dsc_resource 'Shutdown Default Website' do
  resource :website
  property :name, 'Default Web Site'
  property :State, 'Stopped'
  property :PhysicalPath, 'C:\inetpub\wwwroot'
end

node['iis_demo']['sites'].each do |site_name, site_data|
  site_dir = "#{ENV['SYSTEMDRIVE']}\\inetpub\\wwwroot\\#{site_name}"

  dsc_resource "#{site_name} Directory" do
    resource :file
    module_name 'PSDesiredStateConfiguration'
    property :DestinationPath, site_dir
    property :Type, 'Directory'
  end

  dsc_resource "#{site_name} App Pool" do
    resource :WebAppPool
    property :Name, site_name
  end

  dsc_resource "#{site_name} Web Site" do
    resource :WebSite
    property :Name, site_name
    property :ApplicationPool, site_name
    property :PhysicalPath, site_dir
  end

  dsc_resource "#{site_name} Binding" do
    resource :webbinding
    property :websitename, site_name
    property :port, site_data['port']
    property :protocol, 'http'
    property :ipaddress, '*'
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
