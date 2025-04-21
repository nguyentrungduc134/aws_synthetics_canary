// Setup of the common Infrastructure
#module "canary_infra" {
#    source = "./modules/canary-infra"
#    vpc_id = var.vpc_id
#    subnet_ids = var.subnet_ids
#}

// Setup for one Canary. This section can be reused several time.
module "canary" {
    source = "./modules/canary"
    name   = var.name
    runtime_version = var.runtime_version
    take_screenshot = var.take_screenshot
    api_hostname = var.api_hostname
    api_path = var.api_path
    reports-bucket = "duc123"
    role = "lambda"
    #security_group_id = "sg-0bb82b83b6bc31b5c"
    #subnet_ids = var.subnet_ids
    frequency = var.frequency
    alert_sns_topic = var.alert_sns_topic
}
