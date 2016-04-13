### WARNING: This is for demo purposes only
### For production, use your own internal PowerShell Gallery or the public gallery
### Bundling PowerShell Modules in cookbooks is generally a bad idea.

directory "#{ENV['ProgramW6432']}/WindowsPowerShell/Modules/xWebAdministration"

remote_directory "#{ENV['ProgramW6432']}/WindowsPowerShell/Modules/xWebAdministration" do
  source 'xWebAdministration'
  action :create
end