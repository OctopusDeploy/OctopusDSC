describe "tentacle remove" {
  # config = JSON.parse(File.read("c:\\temp\\octopus-configured.marker"))

  #we deliberately dont cleanup the octopus directory, as it contains logs & config
  it "should have created 'c:/Octopus'" {
    Test-Path 'c:/Octopus' | Should -be $true
  }

  it "should have created 'c:/Applications'" {
    Test-Path 'c:/Applications' | Should -be $true
  }

  it "the file 'C:/Program Files/Octopus Deploy/Tentacle/Tentacle.exe' should not exist" {
    Test-Path 'C:/Program Files/Octopus Deploy/Tentacle/Tentacle.exe' | Should -be $false
  }

  it "the service 'OctopusDeploy Tentacle: ListeningTentacle' should not be installed" {
    (Get-Service 'OctopusDeploy Tentacle: ListeningTentacle' -ErrorAction SilentlyContinue) | Should -be $null
  }

  # Listening Tentacle
  # TODO: PESTER CONVERSION: Still to be converted
  # describe octopus_deploy_tentacle(config['OctopusServerUrl'], config['OctopusApiKey'], "ListeningTentacle") do
  #   it { should_not exist }
  # end

  # describe port(10933) do
  #   it { should_not be_listening.with('tcp') }
  # end

  # Polling Tentacle
  it "the service 'OctopusDeploy Tentacle: PollingTentacle' should not be installed" {
    (Get-Service 'OctopusDeploy Tentacle: PollingTentacle' -ErrorAction SilentlyContinue) | Should -be $null
  }

  # TODO: PESTER CONVERSION: Still to be converted
  # describe octopus_deploy_tentacle(config['OctopusServerUrl'], config['OctopusApiKey'], "PollingTentacle") do
  #   it { should_not exist }
  # end

  # Polling Tentacle
  it "the service 'OctopusDeploy Tentacle: PollingTentacle' should not be installed" {
    (Get-Service 'OctopusDeploy Tentacle: PollingTentacle' -ErrorAction SilentlyContinue) | Should -be $null
  }

  # TODO: PESTER CONVERSION: Still to be converted
  # describe octopus_deploy_tentacle(config['OctopusServerUrl'], config['OctopusApiKey'], "PollingTentacle") do
  #   it { should_not exist }
  # end

  # Polling Tentacle with autoregister disabled
  it "the service 'OctopusDeploy Tentacle: PollingTentacleWithoutAutoRegister' should not be installed" {
    (Get-Service 'OctopusDeploy Tentacle: PollingTentacleWithoutAutoRegister' -ErrorAction SilentlyContinue) | Should -be $null
  }

  # TODO: PESTER CONVERSION: Still to be converted
  # describe octopus_deploy_tentacle(config['OctopusServerUrl'], config['OctopusApiKey'], "PollingTentacleWithoutAutoRegister") do
  #   it { should_not exist }
  # end

  # Polling Tentacle with autoregister disabled but thumbprint set
  it "the service 'OctopusDeploy Tentacle: PollingTentacleWithThumbprintWithoutAutoRegister' should not be installed" {
    (Get-Service 'OctopusDeploy Tentacle: PollingTentacleWithThumbprintWithoutAutoRegister' -ErrorAction SilentlyContinue) | Should -be $null
  }

  # TODO: PESTER CONVERSION: Still to be converted
  # describe octopus_deploy_tentacle(config['OctopusServerUrl'], config['OctopusApiKey'], "PollingTentacleWithThumbprintWithoutAutoRegister") do
  #   it { should_not exist }
  # end

  # Worker Tentacle
  it "the service 'OctopusDeploy Tentacle: WorkerTentacle' should not be installed" {
    (Get-Service 'OctopusDeploy Tentacle: WorkerTentacle' -ErrorAction SilentlyContinue) | Should -be $null
  }

  # TODO: PESTER CONVERSION: Still to be converted
  # describe octopus_deploy_worker(config['OctopusServerUrl'], config['OctopusApiKey'], "WorkerTentacle") do
  #   it { should_not exist }
  # end

  # describe windows_dsc do
  #   it { should be_able_to_get_dsc_configuration }
  #   it { should have_test_dsc_configuration_return_true }
  #   it { should have_dsc_configuration_status_of_success }
  # end

  #todo: confirm whether these should be deleted
  #describe windows_registry_key('HKLM:\Software\Octopus\Tentacle') do
  #  it { should_not exist }
  #end
  #
  #describe windows_registry_key('HKLM:\Software\Octopus\Tentacle\Tentacle') do
  #  it { should_not exist }
  #end

  #todo: can we check its been removed from the server somehow?
}
