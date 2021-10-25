describe tentacle_scenario_01_install {
  require 'json'

  config = JSON.parse(File.read("c:\\temp\\octopus-configured.marker"))

  it "should have created c:/Octopus" {
    Test-Path 'c:/Octopus' -PathType Container | should -be $true
  }

  it "should have created c:/Applications" {
    Test-Path 'c:/Applications' -PathType Container | should -be $true
  }

  it "should have created C:/Program Files/Octopus Deploy/Tentacle/Tentacle.exe" {
    Test-Path 'C:/Program Files/Octopus Deploy/Tentacle/Tentacle.exe' -PathType Leaf | should -be $true
  }

  it "should have created registry entries" {
    Test-Path 'HKLM:\Software\Octopus\Tentacle' | should -be $true
    (Get-ItemProperty -Path 'HKLM:\Software\Octopus\Tentacle' -Name "InstallLocation" -ErrorAction SilentlyContinue).InstallLocation | Should -be "C:\\Program Files\\Octopus Deploy\\Tentacle\\"
  }

  it "should have created C:/ProgramData/Octopus/Tentacle/Instances" {
    Test-Path 'C:/ProgramData/Octopus/Tentacle/Instances' -PathType Container | should -be $true
  }

  ### listening tentacle:

  it "should have created the service" {
    Get-Service 'OctopusDeploy Tentacle: ListeningTentacle' | should -not -be $null
  }

  it "should have set the service to running" {
    (Get-Service 'OctopusDeploy Tentacle: ListeningTentacle').Status | should -be "Running"
  }

  it "should have set the service start mode" {
    (Get-Service 'OctopusDeploy Tentacle: ListeningTentacle').StartType | should -be 'Automatic'
  }

  it "should have set the service runas user" {
    (Get-WmiObject Win32_Service -Filter "Name='OctopusDeploy Tentacle: ListeningTentacle'").StartName | should -be 'LocalSystem'
  }

  it "should be listening on port 10933" {
    (Get-NetTCPConnection -LocalPort 10933 -ErrorAction SilentlyContinue).State -contains "Listen" | should -be $true
  }

  describe "Tentacle: Listening Tentacle" {
    BeforeDiscovery {
      . (Join-Path -Path $PSScriptRoot -ChildPath "Get-TentacleDetails.ps1")
    }

    BeforeAll {
      $config = Get-Content "c:\temp\octopus-configured.marker" | ConvertFrom-Json
      $tentacle = Get-TentacleDetails $config['OctopusServerUrl'] config['OctopusApiKey'] "ListeningTentacle"
    }

    it "should exist" {
      $tentacle.Exists | Should -be $true
    }

    it "should be registered with the server" {
      $tentacle.IsRegisteredWithTheServer | Should -be $true
    }

    it "should be online" {
      $tentacle.IsOnline | Should -be $true
    }

    it "should be a listening tentacle" {
      $tentacle.IsListening | Should -be $true
    }

    it "should be in environment 'The-Env'" {
      $tentacle.Environments -contains 'The-Env' | Should -be $true
    }

    it "should have role 'Test-Tentacle'" {
      $tentacle.Roles -contains 'Test-Tentacle' | should -be $true
    }

    it "should have display name 'My Listening Tentacle'" {
      $tentacle.DisplayName | should -be 'My Listening Tentacle'
    }

    it "should be assigned to tenant 'John'" {
      $tentacle.Tenants -contains 'John' | should -be $true
    }

    it "should have tenant tag 'Hosting' and 'Cloud'" {
      $tentacle.TenantTags -contains 'Hosting' | should -be $true
      $tentacle.TenantTags -contains 'Cloud' | should -be $true
    }

    it "should have policy 'Test Policy'" {
      $tentacle.Policy | should -be 'Test Policy'
    }

    it "should have tenanted deployment participation set to 'TenantedOrUntenanted'" {
      $tentacle.TenantedDeploymentParticipation | should -be 'TenantedOrUntenanted'
    }
  }

  it "should have created C:/ProgramData/Octopus/Tentacle/Instances/listeningtentacle.config" {
    Test-Path 'C:/ProgramData/Octopus/Tentacle/Instances/listeningtentacle.config' -PathType Leaf | should -be $true
  }

  it "should set the ConfigurationFilePath" {
      (Get-Content 'C:/ProgramData/Octopus/Tentacle/Instances/listeningtentacle.config' -raw | ConvertFrom-Json).ConfigurationFilePath | Should -be 'C:\Octopus\ListeningTentacleHome\ListeningTentacle\Tentacle.config'
  }

  ### polling tentacle:

  it "should have created the service" {
    Get-Service 'OctopusDeploy Tentacle: PollingTentacle' | should -not -be $null
  }

  it "should have set the service to running" {
    (Get-Service 'OctopusDeploy Tentacle: PollingTentacle').Status | should -be "Running"
  }

  it "should have set the service start mode" {
    (Get-Service 'OctopusDeploy Tentacle: PollingTentacle').StartType | should -be 'Automatic'
  }

  it "should have set the service runas user" {
    (Get-WmiObject Win32_Service -Filter "Name='OctopusDeploy Tentacle: PollingTentacle'").StartName | should -be 'LocalSystem'
  }

  describe "Tentacle: Polling Tentacle" {
    BeforeDiscovery {
      . (Join-Path -Path $PSScriptRoot -ChildPath "Get-TentacleDetails.ps1")
    }

    BeforeAll {
      $config = Get-Content "c:\temp\octopus-configured.marker" | ConvertFrom-Json
      $tentacle = Get-TentacleDetails $config['OctopusServerUrl'] config['OctopusApiKey'] "PollingTentacle"
    }

    it "should exist" {
      $tentacle.Exists | Should -be $true
    }

    it "should be registered with the server" {
      $tentacle.IsRegisteredWithTheServer | Should -be $true
    }

    it "should be online" {
      $tentacle.IsOnline | Should -be $true
    }

    it "should be a polling tentacle" {
      $tentacle.IsPolling | Should -be $true
    }

    it "should be in environment 'Env2'" {
      $tentacle.Environments -contains 'Env2' | Should -be $true
    }

    it "should have role 'Test-Tentacle'" {
      $tentacle.Roles -contains 'Test-Tentacle' | should -be $true
    }

    it "should have display name '$($ENV:COMPUTERNAME)_PollingTentacle'" {
      $tentacle.DisplayName | should -be "$($ENV:COMPUTERNAME)_PollingTentacle"
    }

    it "should not be assigned to any tenants" {
      $tentacle.Tenants.length | should -be 0
    }

    it "should not have any tenant tags" {
      $tentacle.TenantTags.length | should -be 0
    }

    it "should have policy 'Test Policy'" {
      $tentacle.Policy | should -be 'Test Policy'
    }
  }

  it "should have created C:/ProgramData/Octopus/Tentacle/Instances/pollingtentacle.config" {
    Test-Path 'C:/ProgramData/Octopus/Tentacle/Instances/pollingtentacle.config' -PathType Leaf | should -be $true
  }

  it "should have set ConfigurationFilePath in the config file" {
    (Get-Content 'C:/ProgramData/Octopus/Tentacle/Instances/pollingtentacle.config' -raw | ConvertFrom-Json -depth 10).ConfigurationFilePath | Should -be 'C:\Octopus\Polling Tentacle Home\PollingTentacle\Tentacle.config'
  }

  ### listening tentacle (without autoregister, no thumbprint):

  it "should have created the service" {
    Get-Service 'OctopusDeploy Tentacle: ListeningTentacleWithoutAutoRegister' | should -not -be $null
  }

  it "should have set the service to running" {
    (Get-Service 'OctopusDeploy Tentacle: ListeningTentacleWithoutAutoRegister').Status | should -be "Running"
  }

  it "should have set the service start mode" {
    (Get-Service 'OctopusDeploy Tentacle: ListeningTentacleWithoutAutoRegister').StartType | should -be 'Automatic'
  }

  it "should have set the service runas user" {
    (Get-WmiObject Win32_Service -Filter "Name='OctopusDeploy Tentacle: ListeningTentacleWithoutAutoRegister'").StartName | should -be 'LocalSystem'
  }

  it "should be listening on port 10934" {
    (Get-NetTCPConnection -LocalPort 10934 -ErrorAction SilentlyContinue).State -contains "Listen" | should -be $true
  }

  describe "Tentacle: ListeningTentacleWithoutAutoRegister" {
    BeforeDiscovery {
      . (Join-Path -Path $PSScriptRoot -ChildPath "Get-TentacleDetails.ps1")
    }

    BeforeAll {
      $config = Get-Content "c:\temp\octopus-configured.marker" | ConvertFrom-Json
      $tentacle = Get-TentacleDetails $config['OctopusServerUrl'] config['OctopusApiKey'] "ListeningTentacleWithoutAutoRegister"
    }

    it "should exist" {
      $tentacle.Exists | Should -be $true
    }

    it "should be registered with the server" {
      $tentacle.IsRegisteredWithTheServer | Should -be $false
    }
  }

  it "should have created C:/ProgramData/Octopus/Tentacle/Instances/listeningtentaclewithoutautoregister.config" {
    Test-Path 'C:/ProgramData/Octopus/Tentacle/Instances/listeningtentaclewithoutautoregister.config' -PathType Leaf | should -be $true
  }

  it "should have set ConfigurationFilePath in the config file" {
    (Get-Content 'C:/ProgramData/Octopus/Tentacle/Instances/listeningtentaclewithoutautoregister.config' -raw | ConvertFrom-Json -depth 10).ConfigurationFilePath | Should -be 'C:\Octopus\ListeningTentacleWithoutAutoRegisterHome\ListeningTentacleWithoutAutoRegister\Tentacle.config'
  }

  it "should have created the config file" {
    Test-Path 'C:\Octopus\ListeningTentacleWithoutAutoRegisterHome\ListeningTentacleWithoutAutoRegister\Tentacle.config' | should -be $true
  }

  it "should not have registered the tentacle with the server" {
    $content = Get-Content 'C:\Octopus\ListeningTentacleWithoutAutoRegisterHome\ListeningTentacleWithoutAutoRegister\Tentacle.config' -raw
    $content | should -not -match "Tentacle.Communication.TrustedOctopusServers"
  }

  ### listening tentacle (without autoregister, with thumbprint set):

  it "should have created the service" {
    Get-Service 'OctopusDeploy Tentacle: ListeningTentacleWithThumbprintWithoutAutoRegister' | should -not -be $null
  }

  it "should have set the service to running" {
    (Get-Service 'OctopusDeploy Tentacle: ListeningTentacleWithThumbprintWithoutAutoRegister').Status | should -be "Running"
  }

  it "should have set the service start mode" {
    (Get-Service 'OctopusDeploy Tentacle: ListeningTentacleWithThumbprintWithoutAutoRegister').StartType | should -be 'Automatic'
  }

  it "should have set the service runas user" {
    (Get-WmiObject Win32_Service -Filter "Name='OctopusDeploy Tentacle: ListeningTentacleWithThumbprintWithoutAutoRegister'").StartName | should -be 'LocalSystem'
  }

  it "should be listening on port 10935" {
    (Get-NetTCPConnection -LocalPort 10935 -ErrorAction SilentlyContinue).State -contains "Listen" | should -be $true
  }

  describe "Tentacle: ListeningTentacleWithThumbprintWithoutAutoRegister" {
    BeforeDiscovery {
      . (Join-Path -Path $PSScriptRoot -ChildPath "Get-TentacleDetails.ps1")
    }

    BeforeAll {
      $config = Get-Content "c:\temp\octopus-configured.marker" | ConvertFrom-Json
      $tentacle = Get-TentacleDetails $config['OctopusServerUrl'] config['OctopusApiKey'] "ListeningTentacleWithThumbprintWithoutAutoRegister"
    }

    it "should exist" {
      $tentacle.Exists | Should -be $true
    }

    it "should be registered with the server" {
      $tentacle.IsRegisteredWithTheServer | Should -be $true
    }

    it "should be online" {
      $tentacle.IsOnline | Should -be $true
    }

    it "should be a listening tentacle" {
      $tentacle.IsListening | Should -be $true
    }

    it "should be in environment 'The-Env'" {
      $tentacle.Environments -contains 'The-Env' | Should -be $true
    }

    it "should have role 'Test-Tentacle'" {
      $tentacle.Roles -contains 'Test-Tentacle' | should -be $true
    }

    it "should have display name 'ListeningTentacleWithThumbprintWithoutAutoRegister'" {
      $tentacle.DisplayName | should -be "ListeningTentacleWithThumbprintWithoutAutoRegister"
    }

    it "should not be assigned to any tenants" {
      $tentacle.Tenants.length | should -be 0
    }

    it "should not have any tenant tags" {
      $tentacle.TenantTags.length | should -be 0
    }

    it "should have policy 'Default Machine Policy'" {
      $tentacle.Policy | should -be 'Default Machine Policy'
    }
  }

  it "should have created C:/ProgramData/Octopus/Tentacle/Instances/ListeningTentacleWithThumbprintWithoutAutoRegister.config" {
    Test-Path 'C:/ProgramData/Octopus/Tentacle/Instances/ListeningTentacleWithThumbprintWithoutAutoRegister.config' -PathType Leaf | should -be $true
  }

  it "should have set ConfigurationFilePath in the instance config" {
    (Get-Content 'C:/ProgramData/Octopus/Tentacle/Instances/ListeningTentacleWithThumbprintWithoutAutoRegister.config' -raw | ConvertFrom-Json -depth 10).ConfigurationFilePath | Should -be 'C:\Octopus\ListeningTentacleWithThumbprintWithoutAutoRegisterHome\ListeningTentacleWithThumbprintWithoutAutoRegister\Tentacle.config'
  }

  it "should have created the config file" {
    Test-Path 'C:\Octopus\ListeningTentacleWithThumbprintWithoutAutoRegisterHome\ListeningTentacleWithThumbprintWithoutAutoRegister\Tentacle.config' | should -be $true
  }

  it "should have registered the tentacle with the server" {
    $content = Get-Content 'C:\Octopus\ListeningTentacleWithThumbprintWithoutAutoRegisterHome\ListeningTentacleWithThumbprintWithoutAutoRegister\Tentacle.config' -raw
    $content | should -match "Tentacle.Communication.TrustedOctopusServers"
  }

  ### worker tentacle

  it "should have created the service" {
    Get-Service 'OctopusDeploy Tentacle: WorkerTentacle' | should -not -be $null
  }

  it "should have set the service to running" {
    (Get-Service 'OctopusDeploy Tentacle: WorkerTentacle').Status | should -be "Running"
  }

  it "should have set the service start mode" {
    (Get-Service 'OctopusDeploy Tentacle: WorkerTentacle').StartType | should -be 'Automatic'
  }

  it "should have set the service runas user" {
    (Get-WmiObject Win32_Service -Filter "Name='OctopusDeploy Tentacle: WorkerTentacle'").StartName | should -be 'LocalSystem'
  }

  it "should be listening on port 10937" {
    (Get-NetTCPConnection -LocalPort 10937 -ErrorAction SilentlyContinue).State -contains "Listen" | should -be $true
  }

#   describe octopus_deploy_worker(config['OctopusServerUrl'], config['OctopusApiKey'], "WorkerTentacle") do
#     it { should exist }
#     it { should be_registered_with_the_server }
#     it { should be_online }
#     it { should be_listening_worker }
#     it { should have_display_name("My Worker Tentacle")}
#     # TODO check pool membership
#   end

  it "should have created C:/ProgramData/Octopus/Tentacle/Instances/WorkerTentacle.config" {
    Test-Path 'C:/ProgramData/Octopus/Tentacle/Instances/WorkerTentacle.config' -PathType Leaf | should -be $true
  }

  it "should have set ConfigurationFilePath in the config file" {
    (Get-Content 'C:/ProgramData/Octopus/Tentacle/Instances/WorkerTentacle.config' -raw | ConvertFrom-Json -depth 10).ConfigurationFilePath | Should -be 'C:\Octopus\WorkerTentacleHome\WorkerTentacle\Tentacle.config'
  }

  it "should have created C:\Octopus\WorkerTentacleHome\WorkerTentacle\Tentacle.config" {
    Test-Path 'C:\Octopus\WorkerTentacleHome\WorkerTentacle\Tentacle.config' -PathType Leaf | should -be $true
  }

  it "should have set ConfigurationFilePath in the config file" {
    (Get-Content 'C:\Octopus\WorkerTentacleHome\WorkerTentacle\Tentacle.config' -raw | should -match "Tentacle.Communication.TrustedOctopusServers"
  }

  ### listening tentacle with specific service account

  it "should have created the service" {
    Get-Service 'OctopusDeploy Tentacle: ListeningTentacleWithCustomAccount' | should -not -be $null
  }

  it "should have set the service to running" {
    (Get-Service 'OctopusDeploy Tentacle: ListeningTentacleWithCustomAccount').Status | should -be "Running"
  }

  it "should have set the service start mode" {
    (Get-Service 'OctopusDeploy Tentacle: ListeningTentacleWithCustomAccount').StartType | should -be 'Automatic'
  }

  it "should have set the service runas user" {
    (Get-WmiObject Win32_Service -Filter "Name='OctopusDeploy Tentacle: ListeningTentacleWithCustomAccount'").StartName | should -be '.\ServiceUser'
  }

  it "should be listening on port 10936" {
    (Get-NetTCPConnection -LocalPort 10936 -ErrorAction SilentlyContinue).State -contains "Listen" | should -be $true
  }

  describe "Tentacle: ListeningTentacleWithCustomAccount" {
    BeforeDiscovery {
      . (Join-Path -Path $PSScriptRoot -ChildPath "Get-TentacleDetails.ps1")
    }

    BeforeAll {
      $config = Get-Content "c:\temp\octopus-configured.marker" | ConvertFrom-Json
      $tentacle = Get-TentacleDetails $config['OctopusServerUrl'] config['OctopusApiKey'] "ListeningTentacleWithCustomAccount"
    }

    it "should exist" {
      $tentacle.Exists | Should -be $true
    }

    it "should be registered with the server" {
      $tentacle.IsRegisteredWithTheServer | Should -be $true
    }

    it "should be online" {
      $tentacle.IsOnline | Should -be $true
    }

    it "should be a listening tentacle" {
      $tentacle.IsListening | Should -be $true
    }

    it "should be in environment 'The-Env'" {
      $tentacle.Environments -contains 'The-Env' | Should -be $true
    }

    it "should have role 'Test-Tentacle'" {
      $tentacle.Roles -contains 'Test-Tentacle' | should -be $true
    }

    it "should have display name 'ListeningTentacleWithCustomAccount'" {
      $tentacle.DisplayName | should -be "ListeningTentacleWithCustomAccount"
    }

    it "should not be assigned to any tenants" {
      $tentacle.Tenants.length | should -be 0
    }

    it "should not have any tenant tags" {
      $tentacle.TenantTags.length | should -be 0
    }

    it "should have policy 'Default Machine Policy'" {
      $tentacle.Policy | should -be 'Default Machine Policy'
    }
  }

  it "should have created C:/ProgramData/Octopus/Tentacle/Instances/ListeningTentacleWithCustomAccount.config" {
    Test-Path 'C:/ProgramData/Octopus/Tentacle/Instances/ListeningTentacleWithCustomAccount.config' -PathType Leaf | should -be $true
  }

  it "should have set ConfigurationFilePath in the config file" {
    (Get-Content 'C:/ProgramData/Octopus/Tentacle/Instances/ListeningTentacleWithCustomAccount.config' -raw | ConvertFrom-Json -depth 10).ConfigurationFilePath | Should -be 'C:\Octopus\ListeningTentacleWithCustomAccountHome\ListeningTentacleWithCustomAccount\Tentacle.config'
  }

  it "should have created C:\Octopus\ListeningTentacleWithCustomAccountHome\ListeningTentacleWithCustomAccount\Tentacle.config" {
    Test-Path 'C:\Octopus\ListeningTentacleWithCustomAccountHome\ListeningTentacleWithCustomAccount\Tentacle.config' -PathType Leaf | should -be $true
  }

  it "should have set ConfigurationFilePath in the config file" {
    (Get-Content 'C:\Octopus\ListeningTentacleWithCustomAccountHome\ListeningTentacleWithCustomAccount\Tentacle.config' -raw | Should -match "Tentacle.Communication.TrustedOctopusServers"
  }

  it "should be able to get dsc configuration" {
    $ProgressPreference = "SilentlyContinue"
    $state = ""
    do
   {
      $state = (Get-DscLocalConfigurationManager).LCMState
      write-verbose "LCM state is $state"
      Start-Sleep -Seconds 2
    } while ($state -ne "Idle")

    Get-DSCConfiguration -ErrorAction Stop
  }

  it "should get true back from Test-DSCConfiguraiton" {
    $ProgressPreference = "SilentlyContinue"
    $state = ""
    do
    {
      $state = (Get-DscLocalConfigurationManager).LCMState
      write-verbose "LCM state is $state"
      Start-Sleep -Seconds 2
    } while ($state -ne "Idle")
    Test-DSCConfiguration -ErrorAction Stop | should -be $true
  }

  it "should get Success back from Get-DSCConfigurationStatus" {
    $ProgressPreference = "SilentlyContinue"
    $statuses = @(Get-DSCConfigurationStatus -ErrorAction Stop -All)
    $statuses[0].Status | Should -be "Success"
  }
}
