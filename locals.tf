locals {
  valid_environments = keys(local.environment_map)
  validate_environment = index(local.valid_environments, var.tag_value_environment)

  environment_map = {
    development = "Dev"
    qa = "Test"
    integration = "Test"
    preprod = "Stage"
    production = "Production"
    management-dev = "DT_Tooling"
    management = "SP_Tooling"
  }

  common_tags_map = {
    Name         = ""
    Role         = ""
    Environment  = var.tag_value_environment
    Application  = "DataWorks"
    Function     = "Data and Analytics"
    CreatedBy    = "terraform"
    Owner        = "DataWorks"
    Persistence  = "Ignore"
    AutoShutdown = "False"
  }
}
