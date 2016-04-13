include_recipe 'demo::lcm_setup_dsc_resource'
include_recipe 'demo::x_web_administration'

dsc_resource 'Install IIS' do
  resource :windowsfeature
  property :name,  'web-server'
end

service 'w3svc' do
  action [:enable, :start]
end

dsc_resource 'Shutdown Default Website' do
  resource :xwebsite
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
    resource :xWebAppPool
    property :Name, site_name
  end

  dsc_resource "#{site_name} Web Site" do
    resource :xWebSite
    property :Name, site_name
    property :ApplicationPool, site_name
    property :PhysicalPath, site_dir
    property :BindingInfo, cim_instance_array(
      'MSFT_xWebBindingInformation',
      ipaddress: '*',
      protocol: 'http',
      port: site_data['port'])
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
