<powershell>
$ErrorActionPreference = "Continue"

${pre_install}

# Install Chocolatey
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
$env:chocolateyUseWindowsCompression = 'true'
Invoke-WebRequest https://chocolatey.org/install.ps1 -UseBasicParsing | Invoke-Expression

Remove-Alias -Name curl

choco install curl -y

%{ if enable_cloudwatch_agent ~}
curl -sSLo C:\amazon-cloudwatch-agent.msi https://s3.amazonaws.com/amazoncloudwatch-agent/windows/amd64/latest/amazon-cloudwatch-agent.msi
msiexec.exe /i C:\amazon-cloudwatch-agent.msi
Remove-Item C:\amazon-cloudwatch-agent.msi
& "C:\Program Files\Amazon\AmazonCloudWatchAgent\amazon-cloudwatch-agent-ctl.ps1" -a fetch-config -m ec2 -s -c ssm:${ssm_key_cloudwatch_agent_config}
%{ endif ~}

# Install docker
Install-Module -Name DockerMsftProvider -Repository PSGallery -Force
Install-Package -Name docker -ProviderName DockerMsftProvider -Force

# Install dependent tools
choco install git jq awscli archiver -y

${install_config_runner}

${post_install}

Start-Service "actions.runner.*"
