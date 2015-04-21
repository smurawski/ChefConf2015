$ConfigurationData = @{
  AllNodes = @(
    @{
      NodeName = 'localhost'
      Sites = @(
        @{Name = 'Clowns'; Port = 80 },
        @{Name = 'Bears' ; Port = 81 }
      )
    }
  )
  Template = @'
<html><h1>We Love $($Site.Name)</h1></html>
'@
}

configuration SimpleWebserver
{
  import-dscresource -modulename 'ChefConfSamples'
  node $AllNodes.NodeName
  {
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

    WebSite 'ShutdownDefaultWebsite'
    {
      Name = 'Default Web Site'
      State = 'Stopped'
      PhysicalPath = 'C:\inetpub\wwwroot\'
      DependsOn = '[service]w3svc'
    }

    foreach ($Site in $Node.Sites)
    {
      $SiteDir = "$env:systemdrive\inetpub\wwwroot\$($Site.Name)"
      file "$($Site.Name)Directory"
      {
        DestinationPath = $SiteDir
        Type = 'Directory'
        DependsOn = '[windowsfeature]iis'
      }
      WebAppPool "$($Site.Name)AppPool"
      {
        Name = "$($Site.Name)"
        DependsOn = "[file]$($Site.Name)Directory"
      }
      WebSite "$($Site.Name)WebSite"
      {
        Name = $Site.Name
        ApplicationPool = "$($Site.Name)"
        PhysicalPath = $SiteDir
        DependsOn = "[WebAppPool]$($Site.Name)AppPool"
      }
      WebBinding "$($Site.Name)"
      {
        WebsiteName = "$($Site.Name)"
        IPAddress = '*'
        Port = $Site.Port
        Protocol = 'http'
        DependsOn = "[website]$($Site.Name)WebSite"
      }
      File "$($Site.Name) Template"
      {
        DestinationPath = (join-path $SiteDir "Index.htm")
        Contents = $executionContext.InvokeCommand.ExpandString($ConfigurationData.Template)
        DependsOn = "[WebSite]$($Site.Name)WebSite"
      }
    }
  }
}