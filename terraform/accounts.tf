# Copyright Amazon.com, Inc. or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
#
locals {
  accounts = { for path in fileset(path.module, "accounts/*.yaml") : regex("accounts/([\\w-]+)\\.yaml", path)[0] => yamldecode(file(path)) }
}

module "requests" {
  for_each = local.accounts
  source = "./modules/aft-account-request"

  control_tower_parameters = {
    AccountEmail = lookup(each.value, "email", join("", ["info+", each.key, "@inapinch.io"]))
    AccountName  = each.key
    ManagedOrganizationalUnit = lookup(each.value, "ou", "Workloads")
    SSOUserEmail     = lookup(each.value, "sso_email", "info@inapinch.io")
    SSOUserFirstName = lookup(each.value, "sso_first_name", "Ina")
    SSOUserLastName  = lookup(each.value, "sso_last_name", "Pinch")
  }

  account_tags = lookup(each.value, "tags", {})

  change_management_parameters = lookup(each.value, "change_management_parameters", {
    change_reason = "Terraform", change_request_by = "tfc", 
  })
  custom_fields = lookup(each.value, "custom_fields", {})

  account_customizations_name = lookup(each.value, "account_customizations_name", "")
}
