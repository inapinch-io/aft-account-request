# Copyright Amazon.com, Inc. or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
#
locals {
  account_groups = { for path in fileset(path.module, "account_groups/*.yaml") : regex("account_groups/([\\w-]+)\\.yaml", path)[0] => yamldecode(file(path)) }
  accounts = {for value in flatten([for k,v in local.account_groups: [for group in lookup(v, "groups", ["global"]): merge(v, {name = "${k}-${group}"})]]): value["name"] => value}
}

module "requests" {
  for_each = local.accounts
  source = "./modules/aft-account-request"

  control_tower_parameters = {
    AccountEmail = join("", ["info+", each.key, "@inapinch.io"])
    AccountName  = each.key
    ManagedOrganizationalUnit = lookup(each.value, "ou", "Workloads")
    SSOUserEmail     = "info@inapinch.io"
    SSOUserFirstName = "Ina"
    SSOUserLastName  = "Pinch"
  }

  account_tags = each.value["tags"]

  change_management_parameters = each.value["change_management_parameters"]
  custom_fields = each.value["custom_fields"]

  account_customizations_name = each.value["account_customizations_name"]
}
