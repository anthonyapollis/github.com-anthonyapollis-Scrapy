data "azuread_client_config" "current" {}

data "azuread_domains" "default" {
  only_initial = true
}

locals {
  domain = data.azuread_domains.default.domains[0].domain_name
}

resource "azuread_group" "data_team" {
  display_name     = "${local.prefix}-data-team"
  security_enabled = true
  owners           = [data.azuread_client_config.current.object_id]
}

resource "random_password" "user" {
  for_each         = var.users
  length           = 20
  special          = true
  override_special = "!#$%&*-_=+"
}

resource "azuread_user" "users" {
  for_each              = var.users
  user_principal_name   = "${each.key}@${local.domain}"
  display_name          = each.value.display_name
  department            = each.value.department
  password              = random_password.user[each.key].result
  force_password_change = true
}

resource "azuread_group_member" "data_team" {
  for_each         = azuread_user.users
  group_object_id  = azuread_group.data_team.object_id
  member_object_id = each.value.object_id
}
