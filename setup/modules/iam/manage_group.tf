resource "aws_iam_group" "admin_group" {
  name = var.admin_group_name
  path = var.admin_group_path
}

resource "aws_iam_group_policy_attachment" "admin_access" {
  group      = aws_iam_group.admin_group.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_group_policy_attachment" "force_mfa" {
  group      = aws_iam_group.admin_group.name
  policy_arn = aws_iam_policy.force_mfa.arn
}
