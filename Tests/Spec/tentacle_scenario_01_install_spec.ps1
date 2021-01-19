describe "tentacle install" {
  # config = JSON.parse(File.read("c:\\temp\\octopus-configured.marker"))

  it "should have created 'c:/Octopus'" {
    Test-Path 'c:/Octopus' | Should -be $true
  }

  it "should have created 'c:/Applications'" {
    Test-Path 'c:/Applications' | Should -be $true
  }

  it "should have created 'C:/Program Files/Octopus Deploy/Tentacle/Tentacle.exe'" {
    Test-Path 'C:/Program Files/Octopus Deploy/Tentacle/Tentacle.exe' | Should -be $true
  }

  it "should have created 'HKEY_LOCAL_MACHINE\Software\Octopus\Tentacle'" {
    Test-Path 'HKLM:\Software\Octopus\Tentacle' | Should -be $true
  }

  it "should have set 'InstallLocation' to 'C:\\Program Files\\Octopus Deploy\\Tentacle\\'" {
    (Get-ItemProperty -Path 'HKLM:\Software\Octopus\Tentacle' -Name 'InstallLocation').InstallLocation | Should -be "C:\Program Files\Octopus Deploy\Tentacle\"
  }

  it "should have created 'C:/ProgramData/Octopus/Tentacle/Instances'" {
    Test-Path 'C:/ProgramData/Octopus/Tentacle/Instances' | Should -be $true
  }

  ### listening tentacle:

  it "should have registed the 'OctopusDeploy Tentacle: ListeningTentacle' service" {
    (Get-Service 'OctopusDeploy Tentacle: ListeningTentacle' -ErrorAction SilentlyContinue) | Should -not -be $null
  }

  it "should have started the 'OctopusDeploy Tentacle: ListeningTentacle' service" {
    (Get-Service 'OctopusDeploy Tentacle: ListeningTentacle' -ErrorAction SilentlyContinue).Status | Should -be "Running"
  }

  it "should have set the 'OctopusDeploy Tentacle: ListeningTentacle' service to start mode 'Automatic'" {
    (Get-Service 'OctopusDeploy Tentacle: ListeningTentacle' -ErrorAction SilentlyContinue).StartType | Should -be 'Automatic'
  }

  it "should have set the 'OctopusDeploy Tentacle: ListeningTentacle' service to run under 'LocalSystem'" {
    (Get-WmiObject Win32_Service -Filter "Name='OctopusDeploy Tentacle: ListeningTentacle'").StartName | Should -be 'LocalSystem'
  }

  # TODO: PESTER CONVERSION: Still to be converted
  # describe port(10933) do
  #   it { should be_listening.with('tcp') }
  # end

  # describe octopus_deploy_tentacle(config['OctopusServerUrl'], config['OctopusApiKey'], "ListeningTentacle") do
  #   it { should exist }
  #   it { should be_registered_with_the_server }
  #   it { should be_online }
  #   it { should be_listening_tentacle }
  #   it { should be_in_environment('The-Env') }
  #   it { should have_role('Test-Tentacle') }
  #   it { should have_display_name('My Listening Tentacle') }
  #   it { should have_tenant('John') }
  #   it { should have_tenant_tag('Hosting', 'Cloud') }
  #   it { should have_policy('Test Policy') }
  #   it { should have_tenanted_deployment_participation('TenantedOrUntenanted') }
  # end

  it "should have created 'C:/ProgramData/Octopus/Tentacle/Instances/listeningtentacle.config'" {
    Test-Path 'C:/ProgramData/Octopus/Tentacle/Instances/listeningtentacle.config' | Should -be $true
  }

  # TODO: PESTER CONVERSION: Still to be converted
  # config_file = File.read('C:/ProgramData/Octopus/Tentacle/Instances/listeningtentacle.config')
  # config_json = JSON.parse(config_file) # add check for nil
  # describe config_json['ConfigurationFilePath'] do
  #   it { should eq('C:\Octopus\ListeningTentacleHome\ListeningTentacle\Tentacle.config') }
  # end

  ### polling tentacle:

  it "should have registed the 'OctopusDeploy Tentacle: PollingTentacle' service" {
    (Get-Service 'OctopusDeploy Tentacle: PollingTentacle' -ErrorAction SilentlyContinue) | Should -not -be $null
  }

  it "should have started the 'OctopusDeploy Tentacle: PollingTentacle' service" {
    (Get-Service 'OctopusDeploy Tentacle: PollingTentacle' -ErrorAction SilentlyContinue).Status | Should -be "Running"
  }

  it "should have set the 'OctopusDeploy Tentacle: PollingTentacle' service to start mode 'Automatic'" {
    (Get-Service 'OctopusDeploy Tentacle: PollingTentacle' -ErrorAction SilentlyContinue).StartType | Should -be 'Automatic'
  }

  it "should have set the 'OctopusDeploy Tentacle: PollingTentacle' service to run under 'LocalSystem'" {
    (Get-WmiObject Win32_Service -Filter "Name='OctopusDeploy Tentacle: PollingTentacle'").StartName | Should -be 'LocalSystem'
  }

  # TODO: PESTER CONVERSION: Still to be converted
  # describe octopus_deploy_tentacle(config['OctopusServerUrl'], config['OctopusApiKey'], "PollingTentacle") do
  #   it { should exist }
  #   it { should be_registered_with_the_server }
  #   it { should be_online }
  #   it { should be_polling_tentacle }
  #   it { should be_in_environment('Env2') }
  #   it { should have_role('Test-Tentacle') }
  #   it { should have_display_name("#{ENV['COMPUTERNAME']}_PollingTentacle") }
  #   it { should have_policy('Default Machine Policy') }
  # end

  it "should have created 'C:/ProgramData/Octopus/Tentacle/Instances/pollingtentacle.config'" {
    Test-Path 'C:/ProgramData/Octopus/Tentacle/Instances/pollingtentacle.config' | Should -be $true
  }

  # TODO: PESTER CONVERSION: Still to be converted
  # config_file = File.read('C:/ProgramData/Octopus/Tentacle/Instances/pollingtentacle.config')
  # config_json = JSON.parse(config_file)
  # describe config_json['ConfigurationFilePath'] do
  #   it { should eq('C:\Octopus\Polling Tentacle Home\PollingTentacle\Tentacle.config') }
  # end

  ### listening tentacle (without autoregister, no thumbprint):

  it "should have registed the 'OctopusDeploy Tentacle: ListeningTentacleWithoutAutoRegister' service" {
    (Get-Service 'OctopusDeploy Tentacle: ListeningTentacleWithoutAutoRegister' -ErrorAction SilentlyContinue) | Should -not -be $null
  }

  it "should have started the 'OctopusDeploy Tentacle: ListeningTentacleWithoutAutoRegister' service" {
    (Get-Service 'OctopusDeploy Tentacle: ListeningTentacleWithoutAutoRegister' -ErrorAction SilentlyContinue).Status | Should -be "Running"
  }

  it "should have set the 'OctopusDeploy Tentacle: ListeningTentacleWithoutAutoRegister' service to start mode 'Automatic'" {
    (Get-Service 'OctopusDeploy Tentacle: ListeningTentacleWithoutAutoRegister' -ErrorAction SilentlyContinue).StartType | Should -be 'Automatic'
  }

  it "should have set the 'OctopusDeploy Tentacle: ListeningTentacleWithoutAutoRegister' service to run under 'LocalSystem'" {
    (Get-WmiObject Win32_Service -Filter "Name='OctopusDeploy Tentacle: ListeningTentacleWithoutAutoRegister'").StartName | Should -be 'LocalSystem'
  }

  # TODO: PESTER CONVERSION: Still to be converted
  # describe port(10934) do
  #   it { should be_listening.with('tcp') }
  # end

  # describe octopus_deploy_tentacle(config['OctopusServerUrl'], config['OctopusApiKey'], "ListeningTentacleWithoutAutoRegister") do
  #   it { should exist }
  #   it { should_not be_registered_with_the_server }
  # end

  it "should have created 'C:/ProgramData/Octopus/Tentacle/Instances/listeningtentaclewithoutautoregister.config'" {
    Test-Path 'C:/ProgramData/Octopus/Tentacle/Instances/listeningtentaclewithoutautoregister.config' | Should -be $true
  }

  # TODO: PESTER CONVERSION: Still to be converted
  # config_file = File.read('C:/ProgramData/Octopus/Tentacle/Instances/listeningtentaclewithoutautoregister.config')
  # config_json = JSON.parse(config_file)
  # describe config_json['ConfigurationFilePath'] do
  #   it { should eq('C:\Octopus\ListeningTentacleWithoutAutoRegisterHome\ListeningTentacleWithoutAutoRegister\Tentacle.config') }
  # end

  it "'C:\Octopus\ListeningTentacleWithoutAutoRegisterHome\ListeningTentacleWithoutAutoRegister\Tentacle.config' should be a file" {
    Test-Path 'C:\Octopus\ListeningTentacleWithoutAutoRegisterHome\ListeningTentacleWithoutAutoRegister\Tentacle.config' -PathType Leaf | Should -be $true
  }

  # TODO: PESTER CONVERSION: Still to be converted
  # describe file('C:\Octopus\ListeningTentacleWithoutAutoRegisterHome\ListeningTentacleWithoutAutoRegister\Tentacle.config') do
  #   its(:content) { should_not match /Tentacle.Communication.TrustedOctopusServers/}
  # end

  ### listening tentacle (without autoregister, with thumbprint set):

  it "should have registed the 'OctopusDeploy Tentacle: ListeningTentacleWithThumbprintWithoutAutoRegister' service" {
    (Get-Service 'OctopusDeploy Tentacle: ListeningTentacleWithThumbprintWithoutAutoRegister' -ErrorAction SilentlyContinue) | Should -not -be $null
  }

  it "should have started the 'OctopusDeploy Tentacle: ListeningTentacleWithThumbprintWithoutAutoRegister' service" {
    (Get-Service 'OctopusDeploy Tentacle: ListeningTentacleWithThumbprintWithoutAutoRegister' -ErrorAction SilentlyContinue).Status | Should -be "Running"
  }

  it "should have set the 'OctopusDeploy Tentacle: ListeningTentacleWithThumbprintWithoutAutoRegister' service to start mode 'Automatic'" {
    (Get-Service 'OctopusDeploy Tentacle: ListeningTentacleWithThumbprintWithoutAutoRegister' -ErrorAction SilentlyContinue).StartType | Should -be 'Automatic'
  }

  it "should have set the 'OctopusDeploy Tentacle: ListeningTentacleWithThumbprintWithoutAutoRegister' service to run under 'LocalSystem'" {
    (Get-WmiObject Win32_Service -Filter "Name='OctopusDeploy Tentacle: ListeningTentacleWithThumbprintWithoutAutoRegister'").StartName | Should -be 'LocalSystem'
  }

  # TODO: PESTER CONVERSION: Still to be converted
  # describe port(10935) do
  #   it { should be_listening.with('tcp') }
  # end

  # describe octopus_deploy_tentacle(config['OctopusServerUrl'], config['OctopusApiKey'], "ListeningTentacleWithThumbprintWithoutAutoRegister") do
  #   it { should exist }
  #   it { should be_registered_with_the_server }
  #   it { should be_online }
  #   it { should be_listening_tentacle }
  #   it { should be_in_environment('The-Env') }
  #   it { should have_role('Test-Tentacle') }
  #   it { should have_display_name("ListeningTentacleWithThumbprintWithoutAutoRegister")}
  #   it { should have_policy('Default Machine Policy') }
  # end

  it "should have created 'C:/ProgramData/Octopus/Tentacle/Instances/ListeningTentacleWithThumbprintWithoutAutoRegister.config'" {
    Test-Path 'C:/ProgramData/Octopus/Tentacle/Instances/ListeningTentacleWithThumbprintWithoutAutoRegister.config' | Should -be $true
  }

  # TODO: PESTER CONVERSION: Still to be converted
  # config_file = File.read('C:/ProgramData/Octopus/Tentacle/Instances/ListeningTentacleWithThumbprintWithoutAutoRegister.config')
  # config_json = JSON.parse(config_file)
  # describe config_json['ConfigurationFilePath'] do
  #   it { should eq('C:\Octopus\ListeningTentacleWithThumbprintWithoutAutoRegisterHome\ListeningTentacleWithThumbprintWithoutAutoRegister\Tentacle.config') }
  # end

  it "'C:\Octopus\ListeningTentacleWithThumbprintWithoutAutoRegisterHome\ListeningTentacleWithThumbprintWithoutAutoRegister\Tentacle.config' should be a file" {
    Test-Path 'C:\Octopus\ListeningTentacleWithThumbprintWithoutAutoRegisterHome\ListeningTentacleWithThumbprintWithoutAutoRegister\Tentacle.config' -PathType Leaf | Should -be $true
  }

  # TODO: PESTER CONVERSION: Still to be converted
  # describe file('C:\Octopus\ListeningTentacleWithThumbprintWithoutAutoRegisterHome\ListeningTentacleWithThumbprintWithoutAutoRegister\Tentacle.config') do
  #   its(:content) { should match /Tentacle\.Communication\.TrustedOctopusServers.*#{config['OctopusServerThumbprint']}/}
  # end

  ### worker tentacle

  it "should have registed the 'OctopusDeploy Tentacle: WorkerTentacle' service" {
    (Get-Service 'OctopusDeploy Tentacle: WorkerTentacle' -ErrorAction SilentlyContinue) | Should -not -be $null
  }

  it "should have started the 'OctopusDeploy Tentacle: WorkerTentacle' service" {
    (Get-Service 'OctopusDeploy Tentacle: WorkerTentacle' -ErrorAction SilentlyContinue).Status | Should -be "Running"
  }

  it "should have set the 'OctopusDeploy Tentacle: WorkerTentacle' service to start mode 'Automatic'" {
    (Get-Service 'OctopusDeploy Tentacle: WorkerTentacle' -ErrorAction SilentlyContinue).StartType | Should -be 'Automatic'
  }

  it "should have set the 'OctopusDeploy Tentacle: WorkerTentacle' service to run under 'LocalSystem'" {
    (Get-WmiObject Win32_Service -Filter "Name='OctopusDeploy Tentacle: WorkerTentacle'").StartName | Should -be 'LocalSystem'
  }

  # TODO: PESTER CONVERSION: Still to be converted
  # describe port(10937) do
  #   it { should be_listening.with('tcp') }
  # end

  # describe octopus_deploy_worker(config['OctopusServerUrl'], config['OctopusApiKey'], "WorkerTentacle") do
  #   it { should exist }
  #   it { should be_registered_with_the_server }
  #   it { should be_online }
  #   it { should be_listening_worker }
  #   it { should have_display_name("My Worker Tentacle")}
  #   # TODO check pool membership
  # end

  it "should have created 'C:/ProgramData/Octopus/Tentacle/Instances/WorkerTentacle.config'" {
    Test-Path 'C:/ProgramData/Octopus/Tentacle/Instances/WorkerTentacle.config' | Should -be $true
  }

  # TODO: PESTER CONVERSION: Still to be converted
  # config_file = File.read('C:/ProgramData/Octopus/Tentacle/Instances/WorkerTentacle.config')
  # config_json = JSON.parse(config_file)
  # describe config_json['ConfigurationFilePath'] do
  #   it { should eq('C:\Octopus\WorkerTentacleHome\WorkerTentacle\Tentacle.config') }
  # end

  it "'C:\Octopus\WorkerTentacleHome\WorkerTentacle\Tentacle.config' should be a file" {
    Test-Path 'C:\Octopus\WorkerTentacleHome\WorkerTentacle\Tentacle.config' -PathType Leaf | Should -be $true
  }

  # TODO: PESTER CONVERSION: Still to be converted
  # describe file('C:\Octopus\WorkerTentacleHome\WorkerTentacle\Tentacle.config') do
  #   its(:content) { should match /Tentacle\.Communication\.TrustedOctopusServers.*#{config['OctopusServerThumbprint']}/}
  # end

  ### listening tentacle with specific service account

  it "should have registed the 'OctopusDeploy Tentacle: ListeningTentacleWithCustomAccount' service" {
    (Get-Service 'OctopusDeploy Tentacle: ListeningTentacleWithCustomAccount' -ErrorAction SilentlyContinue) | Should -not -be $null
  }

  it "should have started the 'OctopusDeploy Tentacle: ListeningTentacleWithCustomAccount' service" {
    (Get-Service 'OctopusDeploy Tentacle: ListeningTentacleWithCustomAccount' -ErrorAction SilentlyContinue).Status | Should -be "Running"
  }

  it "should have set the 'OctopusDeploy Tentacle: ListeningTentacleWithCustomAccount' service to start mode 'Automatic'" {
    (Get-Service 'OctopusDeploy Tentacle: ListeningTentacleWithCustomAccount' -ErrorAction SilentlyContinue).StartType | Should -be 'Automatic'
  }

  it "should have set the 'OctopusDeploy Tentacle: ListeningTentacleWithCustomAccount' service to run under '.\ServiceUser'" {
    (Get-WmiObject Win32_Service -Filter "Name='OctopusDeploy Tentacle: ListeningTentacleWithCustomAccount'").StartName | Should -be '.\ServiceUser'
  }

  # TODO: PESTER CONVERSION: Still to be converted
  # describe port(10936) do
  #   it { should be_listening.with('tcp') }
  # end

  # describe octopus_deploy_tentacle(config['OctopusServerUrl'], config['OctopusApiKey'], "ListeningTentacleWithCustomAccount") do
  #   it { should exist }
  #   it { should be_registered_with_the_server }
  #   it { should be_online }
  #   it { should be_listening_tentacle }
  #   it { should be_in_environment('The-Env') }
  #   it { should have_role('Test-Tentacle') }
  #   it { should have_display_name('ListeningTentacleWithCustomAccount')}
  #   it { should have_policy('Default Machine Policy') }
  # end

  it "should have created 'C:/ProgramData/Octopus/Tentacle/Instances/ListeningTentacleWithCustomAccount.config'" {
    Test-Path 'C:/ProgramData/Octopus/Tentacle/Instances/ListeningTentacleWithCustomAccount.config' | Should -be $true
  }

  # TODO: PESTER CONVERSION: Still to be converted
  # config_file = File.read('C:/ProgramData/Octopus/Tentacle/Instances/ListeningTentacleWithCustomAccount.config')
  # config_json = JSON.parse(config_file)
  # describe config_json['ConfigurationFilePath'] do
  #   it { should eq('C:\Octopus\ListeningTentacleWithCustomAccountHome\ListeningTentacleWithCustomAccount\Tentacle.config') }
  # end

  it "'C:\Octopus\ListeningTentacleWithCustomAccountHome\ListeningTentacleWithCustomAccount\Tentacle.config' should be a file" {
    Test-Path 'C:\Octopus\ListeningTentacleWithCustomAccountHome\ListeningTentacleWithCustomAccount\Tentacle.config' -PathType Leaf | Should -be $true
  }

  # TODO: PESTER CONVERSION: Still to be converted
  # describe file('C:\Octopus\ListeningTentacleWithCustomAccountHome\ListeningTentacleWithCustomAccount\Tentacle.config') do
  #   its(:content) { should match /Tentacle\.Communication\.TrustedOctopusServers.*#{config['OctopusServerThumbprint']}/}
  # end

  # describe windows_dsc do
  #   it { should be_able_to_get_dsc_configuration }
  #   it { should have_test_dsc_configuration_return_true }
  #   it { should have_dsc_configuration_status_of_success }
  # end
}
