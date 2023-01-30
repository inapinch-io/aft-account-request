locals {
  ous = { for path in fileset(path.module, "organizational_units/*.yaml") : regex("organizational_units/([\\w-]+)\\.yaml", path)[0] => yamldecode(file(path)) }
}

resource "aws_organizations_organizational_unit" "ous" {
  for_each = local.ous
  name      = each.key
  parent_id = lookup(each.value, "parent_id", var.default_ou_id)
  tags = lookup(each.value, "tags", {})
}

variable "default_ou_id" {
  type = string
}