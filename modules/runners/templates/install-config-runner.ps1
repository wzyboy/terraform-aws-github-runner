$ErrorActionPreference = "Continue"
mkdir \actions-runner ; Set-Location \actions-runner

aws s3 cp ${s3_location_runner_distribution} actions-runner.zip
arc unarchive -mkdirs actions-runner.zip
Remote-Item actions-runner.zip

$InstanceId = Get-EC2InstanceMetadata -Category InstanceId
$Region = Get-EC2InstanceMetadata -Category IdentityDocument | ConvertFrom-Json | Select-Object -ExpandProperty region

Write-Host "Waiting for configuration..."

$config = "null"
$i = 0
do {
    $config = aws ssm get-parameters --names "${environment}-$InstanceId" --with-decryption --region $Region | jq -r ".Parameters | .[0] | .Value"
    Write-Host "Waiting for configuration... ($i/30)"
    Start-Sleep 1
    $i++
} while (($config -eq "null") -and ($i -lt 30))

aws ssm delete-paramter --name ${environment}-$INSTANCE_ID --region $REGION

$configCmd = ".\config.cmd --unattended --name $InstanceId --work `"_work`" $config"
Invoke-Expression $configCmd
