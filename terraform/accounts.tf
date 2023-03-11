# Copyright Amazon.com, Inc. or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
#
locals {
  account_groups = [ for path in fileset(path.module, "account_groups/*.yaml") : merge(yamldecode(file(path)), { name = regex("account_groups/([\\w-]+)\\.yaml", path)[0]}) ]
  accounts = { 
    for account in flatten([ 
      for definition in local.account_groups: [
        for key, group in lookup(definition, "groups", { global = {} }): 
          merge(group, {name = join("-", [definition["name"], key])}) 
        ] 
      ]): 
      account["name"] => account  
  }
}

module "requests" {
  for_each = local.accounts
  source = "./modules/aft-account-request"

  control_tower_parameters = {
    AccountEmail = lookup(each.value, "email", join("", ["info+", each.key, "@inapinch.io"]))
    AccountName  = each.key
    ManagedOrganizationalUnit = lookup(each.value, "ou", "Workloads")
    SSOUserEmail     = lookup(each.value, "sso_email", "info@inapinch.io")
    SSOUserFirstName = lookup(each.value, "sso_first_name", "Info")
    SSOUserLastName  = lookup(each.value, "sso_last_name", "Pinch")
  }

  account_tags = lookup(each.value, "tags", {})

  change_management_parameters = lookup(each.value, "change_management_parameters", {
    change_reason = "Terraform", change_requested_by = "aft", 
  })
  custom_fields = lookup(each.value, "custom_fields", {})

  account_customizations_name = lookup(each.value, "account_customizations_name", join("-", [lower(lookup(each.value, "ou", "Workloads")), "customizations"]))
}
