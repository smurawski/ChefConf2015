function Get-TargetResource 
{
    [OutputType([System.Collections.Hashtable])]
    param (
      [parameter(Mandatory)]
      [string]
      $WebsiteName,
      [parameter(Mandatory)]
      [System.UInt16]
      $Port,
      [parameter(Mandatory)]
      [ValidateSet('http', 'https')]
      [string]
      $Protocol,
      [parameter(Mandatory)]
      [string]
      $IPAddress,
      [parameter()]
      [string[]]
      $HostName,
      [string] 
      $CertificateThumbprint,
      [ValidateSet('Personal', 'WebHosting')]
      [string] 
      $CertificateStoreName
    )

    
    $TargetResource = @{}
    $MatchingBinding = Get-MatchingWebBinding -Name $WebsiteName -port $Port -Protocol $Protocol -IPAddress $IPAddress

    if ($MatchingBinding)
    {
      $TargetResource.WebsiteName = $WebsiteName
      $TargetResource.Port = $Port
      $TargetResource.Protocol = $Protocol
      $TargetResource.IPAddress = $IPAddress
      $TargetResource.HostName = $MatchingBinding.HostName | where {$HostName -contains $_ }
      $TargetResource.CertificateThumbprint = $MatchingBinding.CertificateThumbprint
      $TargetResource.CertificateStoreName = $MatchingBinding.CertificateStoreName
    }
    
    return $TargetResource

}

function Get-MatchingWebBinding
{
  param ([string]$Name, [uint16]$Port, [string]$Protocol, [string]$IPAddress)
 
  Get-WebBinding @PSBoundParameters |
    New-WebBindingObject 
}

function Set-TargetResource
{
  param (
      [parameter(Mandatory)]
      [string]
      $WebsiteName,
      [parameter(Mandatory)]
      [System.UInt16]
      $Port,
      [parameter(Mandatory)]
      [ValidateSet('http', 'https')]
      [string]
      $Protocol,
      [parameter(Mandatory)]
      [string]
      $IPAddress,
      [parameter()]
      [string[]]
      $HostName,
      [string] 
      $CertificateThumbprint,
      [ValidateSet('Personal', 'WebHosting')]
      [string] 
      $CertificateStoreName
    )

    $BindingParameters = @{
      Name = $WebsiteName 
      Protocol = $Protocol
      Port = $Port
      IPAddress = $IPAddress
    }
    if ($PSBoundParameters.ContainsKey('HostName'))
    {
      foreach ($HostHeader in $HostName)
      {
        $BindingParameters.HostHeader = $HostName
        NewWebBinding -Properties $BindingParameters
      }
    }
    else 
    {
      NewWebBinding -Properties $BindingParameters      
    }


    if ($PSBoundParameters.ContainsKey('CertificateThumbprint'))
    {
      $MatchingBinding = Get-MatchingWebBinding -Name $WebsiteName -Port $Port -Protocol $Protocol -IPAddress $IPAddress
      foreach ($ExistingBinding in $MatchingBinding)
      {
        if (($ExistingBinding.CertificateThumbprint -notlike $CertificateThumbprint) -and
          ($ExistingBinding.CertificateStoreName -notlike $CertificateStoreName))
        {
          if ( -not [string]::IsNullOrEmpty($ExistingBinding.CertificateThumbprint))
          {
            $ExistingBinding.BindingInfo.RemoveSslCertificate()
          }
          $ExistingBinding.BindingInfo.AddSslCertificate($CertificateThumbprint, $CertificateStoreName)
        }
      }
    }

    #Wait for binding to get picked up.
    Start-Sleep -seconds 1
    #Make sure the site is running (especially for the first binding)
    if (Get-WebSite -Name $WebsiteName | where {$_.state -notlike 'Started'})
    { 
      Start-Website $WebsiteName
    } 
}

function NewWebBinding 
{
  param ($properties)
  try 
  {
    Write-Verbose "Creating binding for site $($properties.name) with "
    foreach ($Key in $properties.keys)
    {
      Write-Verbose "`t$key : $($properties[$key])"
    }
    New-WebBinding @properties -ErrorAction Stop
    Write-Verbose "Binding created."
  }
  catch [Exception]
  {
    Write-Verbose "Site $($Properties.Name) already has this binding." 
  }
}

function Test-TargetResource
{
  [OutputType([System.Boolean])]
  param (
      [parameter(Mandatory)]
      [string]
      $WebsiteName,
      [parameter(Mandatory)]
      [System.UInt16]
      $Port,
      [parameter(Mandatory)]
      [ValidateSet('http', 'https')]
      [string]
      $Protocol,
      [parameter(Mandatory)]
      [string]
      $IPAddress,
      [parameter()]
      [string[]]
      $HostName,
      [string] 
      $CertificateThumbprint,
      [ValidateSet('Personal', 'WebHosting')]
      [string] 
      $CertificateStoreName
    )


  $MatchingBinding = Get-MatchingWebBinding -Name $WebsiteName -Port $Port -IPAddress $IPAddress -Protocol $Protocol

  if ($MatchingBinding)
  { 
    return (ValidateHostName -HostName $HostName -MatchingBinding $MatchingBinding) -and
      (ValidateSslSetting -CertificateThumbprint $CertificateThumbprint -CertificateStoreName $CertificateStoreName -MatchingBinding $MatchingBinding)
  }
  elseif (get-website $WebsiteName)
  {
    Write-Verbose "Website $WebsiteName exists, but has no existing bindings."
    return $false
  }
  else 
  {
      throw "Website $WebsiteName does not exist. Please create a website before attempting to create a binding."
  }
}

function ValidateHostName
{
  [cmdletbinding()]
  param ([string[]]$HostName, [psobject[]]$MatchingBinding)
  $IsValid = $true

  $HostNameIsEmpty = $false
  if ($HostName.count -eq 0)
  {
    $HostNameIsEmpty = $true
    Write-Verbose "$HostName is empty"
  }

  [string[]]$MatchingBindingHostNames = $MatchingBinding.HostName | Where {-not [string]::IsNullOrEmpty($_)}
  $MatchingBindingHostNameIsEmpty = $false
  if ($MatchingBindingHostNames.count -eq 0)
  {
    $MatchingBindingHostNameIsEmpty = $true
    Write-Verbose "MatchingBindingHostName is empty"
  }
  
  if ($MatchingBindingHostNameIsEmpty -and $HostNameIsEmpty)
  {
    return $IsValid
  }

  $IsValid = $IsValid -and ($HostName.count -eq $MatchingBinding.HostName.count)
  if ($IsValid -and $HostName.count -gt 0)
  {
    foreach ($Binding in $MatchingBinding)
    {
      $IsValid = $IsValid -and ($HostName -contains $Binding.HostName)
    }
  }
  return $IsValid
}

function ValidateSslSetting
{
  param ([string]$CertificateThumbprint, [string]$CertificateStoreName, [psobject[]]$MatchingBinding)

  $IsValid = $true

  foreach ($Binding in $MatchingBinding){
    $IsValid = $IsValid -and 
      ($CertificateThumbprint -like $Binding.CertificateThumbprint) -and
      ($CertificateStoreName -like $Binding.CertificateStoreName)
  }

  return $IsValid
}

function New-WebBindingObject
{
    Param
    (
        [parameter(valueFromPipeline)]
        [object]
        $BindingInfo
    )

    process
    {
      #First split properties by ']:'. This will get IPv6 address split from port and host name
      $Split = $BindingInfo.BindingInformation.split("[]")
      if($Split.count -gt 1)
      {
          $IPAddress = $Split.item(1)
          $Port = $split.item(2).split(":").item(1)
          $HostName = $split.item(2).split(":").item(2)
      }
      else
      {
          $SplitProps = $BindingInfo.BindingInformation.split(":")
          $IPAddress = $SplitProps.item(0)
          $Port = $SplitProps.item(1)
          $HostName = $SplitProps.item(2)
      }
         
      $WebBindingObject = New-Object PSObject -Property @{
        BindingInfo = $BindingInfo
        Protocol = $BindingInfo.protocol;
        IPAddress = $IPAddress;
        Port = $Port;
        HostName = $HostName;
        CertificateThumbprint = $BindingInfo.CertificateHash;
        CertificateStoreName = $BindingInfo.CertificateStoreName
      }
      return $WebBindingObject
    }
}