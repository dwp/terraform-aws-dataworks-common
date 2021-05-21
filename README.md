# terraform-aws-dataworks-common
A Terraform module to house common configuration for the DWP DataWorks team.

## How to use

This module should be imported by all DWP DataWorks repositories like this:

```
module dataworks_common {
  source = "dwp/dataworks-common/aws"

  tag_value_environment = "qa"
}
```

## Tags

One of the main functions of this repo is to enforce DataWorks tagging policy on all resources. When you import the module as above, you will need to provide the following inputs for the tags:

* `tag_value_environment` -> The name of the environment, valid values are development/qa/integration/preprod/production/management-dev/management

### Using tags locally

The module has a `common_tags` output which you can use for your local module. To do that, create a local like this after you have imported the module:

```
locals {
    common_tags = module.dataworks_common.common_tags
}
```

### Overidding tags

The following tags *should NEVER be overidden*:

* `Application`
* `Function`
* `Environment`
* `CreatedBy`

The following tags can be overriden but the value must be a valid value:

* `Persistence` -> See https://engineering.dwp.gov.uk/products/aws-compute-time-based-provisioning/#what-tags-are-needed-for-the-function-to-operate for the valid tag values (defaults to `Ignore`)
* `AutoShutdown` -> Only valid for ASGs, if set to `True` then scales down the ASG every night via a lambda (defaults to `False`)

The following tags *must be overriden*:

* `Name` -> The name of the resource (i.e. `kafka_to_hbase_auto_scaling_group`)
* `Role` -> Use this for the resource functionality (i.e. `kafka_data_ingestion`)
* `Owner` -> The repository storing this resource (i.e. `dataworks-aws-ingest-consumers`)

The best way to override tags is to create a local tags list for the tags you override at the repository level like this:

```
locals {
    persistence_tag_value = {
        development = "mon-fri,08:00-18:00"
        qa = "mon-fri,08:00-18:00"
        integration = "mon-fri,08:00-18:00"
        preprod = "Ignore"
        production = "Ignore"
    }
    auto_shutdown_tag_value = {
        development = "True"
        qa = "True"
        integration = "True"
        preprod = "False"
        production = "False"
    }
    overridden_tags = {
        Role         = "kafka_data_ingestion"
        Owner        = "dataworks-aws-ingest-consumers"
        Persistence  = local.persistence_tag_value[local.environment]
        AutoShutdown = local.auto_shutdown_tag_value[local.environment]
    }
    common_repo_tags = "${merge(local.common_tags, local.overridden_tags)}"
}
```

Then you can use this on specific resources, like this:

```
tags = "${merge(local.common_repo_tags, map("Name", "kafka_to_hbase_launch_template"))}"
```

### Default tags on AWS provider

Starting from AWS provider version `3.38.0` or later, default tags can be provided at the provider level. You should do this in your repo so that every single resource gets the tags it needs. You can add them like this (provided the local values above have been created):

```
provider "aws" {
    default_tags {
        tags = local.common_repo_tags
    }
}
```

Instead of overridding on a specific resource using the merge, all you then need to do is provide the tags that you want to override (or add if specific tags are on this resource). The provider takes care of the merge and where there are clashes, uses the resource tags for the value (see https://www.hashicorp.com/blog/default-tags-in-the-terraform-aws-provider for more details):

```
resource "aws_launch_template" "kafka_to_hbase_launch_template" {
    tags = {
        Name = "kafka_to_hbase_launch_template"
    }
}
```

The only caveat is with ASGs, where the provider default tags do not work, so you will need to use the merge method for ASGs as before:

```
resource "aws_autoscaling_group" "kafka_to_hbase_launch_template" {
    tags = "${merge(local.common_repo_tags, map("Name", "kafka_to_hbase_autoscaling_group"))}"
}
```
