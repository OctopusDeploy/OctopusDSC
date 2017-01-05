#!/bin/bash

function check_plugin_installed() {
    param=$1

    vagrant plugin list | grep -i "$param " > /dev/null

    if [ $? == 0 ]; then
      echo "Vagrant plugin $param exists - good."
    else
      echo "Vagrant plugin $param not installed."
      vagrant plugin install $param
    fi
}

function check_env_var() {
    param=$1
    if [ -z "${!param}" ]; then
        echo "Please set the $param environment variable"
        exit 1
    fi
}

check_env_var AWS_ACCESS_KEY_ID
check_env_var AWS_SECRET_ACCESS_KEY
check_env_var AWS_SUBNET_ID
check_env_var AWS_SECURITY_GROUP_ID

which vagrant > /dev/null
if [ $? != 0 ]; then
  echo "Please install vagrant from vagrantup.com."
  exit 1
fi
echo "Vagrant installed - good."

POWERSHELL_INSTALLED=0
which powershell > /dev/null
if [ $? != 0 ]; then
  POWERSHELL_INSTALLED=1
  echo "Powershell does not appear to be installed. To install, see https://github.com/PowerShell/PowerShell/blob/master/docs/installation/linux.md."
else
  echo "Powershell installed - good."
fi

check_plugin_installed "vagrant-aws"
check_plugin_installed "vagrant-aws-winrm"
check_plugin_installed "vagrant-dsc"
check_plugin_installed "vagrant-winrm"
check_plugin_installed "vagrant-winrm-syncedfolders"

if [ $POWERSHELL_INSTALLED == 0 ]; then
  if [ -z "$PSSCRIPTANALZYER_PATH" ]; then
    if [ -e /opt/PowerShell/PSScriptAnalyzer/out/PSScriptAnalyzer ]; then
      PSSCRIPTANALZYER_PATH = "/opt/PowerShell/PSScriptAnalyzer/out/PSScriptAnalyzer"
    else
      echo "Could not find PSScriptAnalyzer. Please set environment variable PSSCRIPTANALZYER_PATH to the folder containing PSScriptAnalyzer.psm1."
      echo "Skipping PSScriptAnalyzer testing."
    fi
  fi

  if [ -n "$PSSCRIPTANALZYER_PATH" ]; then
    echo "Running PSScriptAnalyzer"
    powershell -command "Import-Module $PSSCRIPTANALZYER_PATH; \$results = Invoke-ScriptAnalyzer ./OctopusDSC/DSCResources -recurse -exclude @('PSUseShouldProcessForStateChangingFunctions', 'PSAvoidUsingPlainTextForPassword', 'PSAvoidUsingUserNameAndPassWordParams', 'PSAvoidUsingConvertToSecureStringWithPlainText'); write-output \$results; exit \$results.length"
    if [ $? != 0 ]; then
      echo "PSScriptAnalyzer found issues."
      exit 1
    fi
  fi

  echo "Running Pester Tests"
  powershell -command "Invoke-Pester -OutputFile PesterTestResults.xml -OutputFormat NUnitXml -EnableExit"
  if [ $? != 0 ]; then
    echo "Pester tests failed."
    exit 1
  fi
fi

echo "Running 'vagrant up --provider virtualbox'"
time vagrant up --provider virtualbox # --debug &> vagrant.log

echo "Dont forget to run 'vagrant destroy -f' when you have finished"