locals {
  environment = "windows"
  aws_region  = "us-east-1"
}

resource "random_password" "random" {
  length = 28
}

module "runners" {
  source = "../../"

  aws_region = local.aws_region
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  runner_os   = "win"
  environment = local.environment
  tags = {
    Project = "ProjectX"
  }

  github_app = {
    key_base64     = var.github_app_key_base64
    id             = var.github_app_id
    client_id      = var.github_app_client_id
    client_secret  = var.github_app_client_secret
    webhook_secret = random_password.random.result
  }

  # webhook_lambda_zip                = "lambdas-download/webhook.zip"
  # runner_binaries_syncer_lambda_zip = "lambdas-download/runner-binaries-syncer.zip"
  # runners_lambda_zip                = "lambdas-download/runners.zip"

  enable_organization_runners = false
  runner_extra_labels         = "windows,example"

  # enable access to the runners via SSM
  enable_ssm_on_runners = true

  ami_filter = {
    name = ["Windows_Server-20H2-English-Core-ContainersLatest-*"]
  }

  runner_log_files = [
    {
      "log_group_name" : "user_data",
      "prefix_log_group" : true,
      "file_path" : var.runner_os == "linux" ? "/var/log/user-data.log" : "C:/UserData.log",
      "log_stream_name" : "{instance_id}"
    },
    {
      "log_group_name" : "runner",
      "prefix_log_group" : true,
      "file_path" : var.runner_os == "linux" ? "/home/runners/actions-runner/_diag/Runner_**.log" : "C:/actions-runner/_diag/Runner_**.log",
      "log_stream_name" : "{instance_id}"
    }
  ]

  # Uncommet idle config to have idle runners from 9 to 5 in time zone Amsterdam
  # Idling is recommended as Windows runners can take some time to spin up
  # idle_config = [{
  #   cron      = "* * 9-17 * * *"
  #   timeZone  = "Europe/Amsterdam"
  #   idleCount = 1
  # }]
}
