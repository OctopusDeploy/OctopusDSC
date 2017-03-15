#!/bin/bash

function check_plugin_installed() {
  plugin_name=$1
  plugin_version=$2

  if [ -z "$plugin_version" ]; then
    vagrant plugin list | grep -i "$plugin_name " > /dev/null

    if [ $? == 0 ]; then
      echo "Vagrant plugin $plugin_name exists - good."
    else
      echo "Vagrant plugin $plugin_name not installed."
      vagrant plugin install $plugin_name
    fi
  else
    vagrant plugin list | grep -i "$plugin_name ($plugin_version)" > /dev/null

    if [ $? == 0 ]; then
      echo "Vagrant plugin $plugin_name v$plugin_version exists - good."
    else
      echo "Vagrant plugin $plugin_name v$plugin_version not installed."
      vagrant plugin install $plugin_name --plugin-version "$plugin_version"
    fi
  fi
}

function check_env_var() {
    param=$1
    if [ -z "${!param}" ]; then
        echo "Please set the $param environment variable"
        exit 1
    fi
}

check_env_var AZURE_VM_PASSWORD
check_env_var AZURE_SUBSCRIPTION_ID
check_env_var AZURE_TENANT_ID
check_env_var AZURE_CLIENT_ID
check_env_var AZURE_CLIENT_SECRET

which vagrant > /dev/null
if [ $? != 0 ]; then
  echo "Please install vagrant from vagrantup.com."
  exit 1
fi
echo "Vagrant installed - good."

which aws > /dev/null
if [ $? != 0 ]; then
  echo "Please install aws-cli. See http://docs.aws.amazon.com/cli/latest/userguide/installing.html."
  exit 1
fi
echo "AWS CLI installed - good."

POWERSHELL_INSTALLED=0
which powershell > /dev/null
if [ $? != 0 ]; then
  POWERSHELL_INSTALLED=1
  echo "Powershell does not appear to be installed. To install, see https://github.com/PowerShell/PowerShell/blob/master/docs/installation/linux.md."
else
  echo "Powershell installed - good."
fi

check_plugin_installed "vagrant-dsc"
check_plugin_installed "vagrant-azure" "2.0.0.pre6"
check_plugin_installed "vagrant-winrm"
check_plugin_installed "vagrant-winrm-syncedfolders"

if [ $POWERSHELL_INSTALLED == 0 ]; then
  echo "Running PSScriptAnalyzer"
read -r -d '' SCRIPT << EOM
Import-Module PSScriptAnalyzer
\$excludedRules = @('PSUseShouldProcessForStateChangingFunctions', 'PSAvoidUsingPlainTextForPassword', 'PSAvoidUsingUserNameAndPassWordParams', 'PSAvoidUsingConvertToSecureStringWithPlainText')
\$results = Invoke-ScriptAnalyzer ./OctopusDSC/DSCResources -recurse -exclude \$excludedRules
write-output \$results
write-output "PSScriptAnalyzer found \$(\$results.length) issues"
exit \$results.length
EOM
  powershell -command "$SCRIPT"
  if [ $? != 0 ]; then
    echo "Aborting as PSScriptAnalyzer found issues."
    exit 1
  fi

  echo "Running Pester Tests"
  powershell -command "Invoke-Pester -OutputFile PesterTestResults.xml -OutputFormat NUnitXml -EnableExit"
  if [ $? != 0 ]; then
    echo "Pester tests failed."
    exit 1
  fi
fi

echo "Running 'vagrant up --provider azure'"
time vagrant up --provider azure # --debug &> vagrant.log
VAGRANT_UP_EXIT_CODE=$?
echo "'vagrant up' exited with exit code $VAGRANT_UP_EXIT_CODE"

if [ $VAGRANT_UP_EXIT_CODE != 0 ]; then
  echo "Vagrant up failed with exit code $VAGRANT_UP_EXIT_CODE"
  echo "##teamcity[buildStatus text='{build.status.text}. Vagrant failed.']"
  exit $VAGRANT_UP_EXIT_CODE
fi

echo "Dont forget to run 'cleanup-azure.sh' when you have finished"
