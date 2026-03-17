resource "aws_iam_user" "users" {
  for_each = toset(var.users)
  name     = each.key
  path     = "/user"
  tags     = merge(var.tags, { ManagedBy = "terraform" })
}

resource "aws_iam_user_group_membership" "admin_members" {
  for_each = toset(var.users)
  user     = aws_iam_user.users[each.key].name
  groups   = [aws_iam_group.admin_group.name]
}
