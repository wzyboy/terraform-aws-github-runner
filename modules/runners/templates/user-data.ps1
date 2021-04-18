<powershell>
$ErrorActionPreference = "Continue"
$VerbosePreference = "Continue"
Start-Transcript -Path "C:\UserData.log" -Append

${pre_install}

# Install Chocolatey
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
$env:chocolateyUseWindowsCompression = 'true'
Invoke-WebRequest https://chocolatey.org/install.ps1 -UseBasicParsing | Invoke-Expression

Remove-Item Alias:curl
Remove-Item Alias:wget

Write-Host "Installing curl..."
choco install curl -y -v

Get-Command curl

%{ if enable_cloudwatch_agent ~}
Write-Host "Setting up cloudwatch agent..."
curl -sSLo C:\amazon-cloudwatch-agent.msi https://s3.amazonaws.com/amazoncloudwatch-agent/windows/amd64/latest/amazon-cloudwatch-agent.msi
msiexec.exe /i C:\amazon-cloudwatch-agent.msi
Remove-Item C:\amazon-cloudwatch-agent.msi
$loop = 0;
while (!(Test-Path 'C:\Program Files\Amazon\AmazonCloudWatchAgent\amazon-cloudwatch-agent-ctl.ps1') -and $loop -lt 5) {
    $loop++
    Start-Sleep -Seconds 2
}
& 'C:\Program Files\Amazon\AmazonCloudWatchAgent\amazon-cloudwatch-agent-ctl.ps1' -a fetch-config -m ec2 -s -c ssm:${ssm_key_cloudwatch_agent_config}
%{ endif ~}

# Install docker
Write-Host "Initializing docker module..."
Install-Module -Name DockerMsftProvider -Repository PSGallery -Force -Confirm:$False
Install-Package -Name docker -ProviderName DockerMsftProvider -Force -Confirm:$False

# Install dependent tools
Write-Host "Installing additional development tools"
choco install git jq awscli archiver -y

${install_config_runner}

${post_install}

Start-Service "actions.runner.*"
Stop-Transcript
</powershell>