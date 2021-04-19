<powershell>
$ErrorActionPreference = "Continue"
$VerbosePreference = "Continue"
Start-Transcript -Path "C:\UserData.log" -Append

${pre_install}

# Install Chocolatey
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
$env:chocolateyUseWindowsCompression = 'true'
Invoke-WebRequest https://chocolatey.org/install.ps1 -UseBasicParsing | Invoke-Expression

# Add Chocolatey to powershell profile
$ChocoProfileValue = @'
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

Remove-Item Alias:curl
Remove-Item Alias:wget

refreshenv
'@
# Write it to the $profile location
Set-Content -Path "$PsHome\Microsoft.PowerShell_profile.ps1" -Value $ChocoProfileValue -Force
# Source it
. "$PsHome\Microsoft.PowerShell_profile.ps1"

Write-Host "Installing curl..."
choco install curl -y

refreshenv

Get-Command curl

%{ if enable_cloudwatch_agent ~}
Write-Host "Setting up cloudwatch agent..."
curl -sSLo C:\amazon-cloudwatch-agent.msi https://s3.amazonaws.com/amazoncloudwatch-agent/windows/amd64/latest/amazon-cloudwatch-agent.msi
msiexec.exe /i C:\amazon-cloudwatch-agent.msi
Remove-Item C:\amazon-cloudwatch-agent.msi
$loop = 0;
while (!(Test-Path 'C:\Program Files\Amazon\AmazonCloudWatchAgent\amazon-cloudwatch-agent-ctl.ps1') -and $loop -lt 5) {
    $loop++
    Start-Sleep -Seconds 5
}

$cloudwatchAgentScript = @'
& 'C:\Program Files\Amazon\AmazonCloudWatchAgent\amazon-cloudwatch-agent-ctl.ps1' -a fetch-config -m ec2 -s -c ssm:${ssm_key_cloudwatch_agent_config}
'@
Set-Content -Path "C:\SetupCloudwatch.ps1" -Value $cloudwatchAgentScript

$action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument "C:\SetupCloudwatch.ps1"
$trigger = New-ScheduledTaskTrigger -Once -At $([DateTime]::UtcNow.AddMinutes(5))
$principal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
Register-ScheduledTask -TaskName 'ReconfigureCloudwatchAgent' -TaskPath '\GitHubActionsRunner\' -Action $action -Trigger $trigger -Principal $principal -Description 'Reconfigures the Cloudwatch Agent' -ErrorAction Stop
%{ endif ~}

# Install dependent tools
Write-Host "Installing additional development tools"
choco install git jq awscli archiver -y
refreshenv

${install_config_runner}
${post_install}

Stop-Transcript
</powershell>