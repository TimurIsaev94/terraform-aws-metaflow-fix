###############################################################################
# TRUST POLICY (EC2 instances assume the role)
###############################################################################
data "aws_iam_policy_document" "ecs_instance_trust" {
  statement {
    sid     = "EC2AssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

###############################################################################
# IAM ROLE FOR ECS CONTAINER INSTANCES
###############################################################################
resource "aws_iam_role" "ecs_instance" {
  name               = local.ecs_instance_role_name
  description        = "Instance role passed to AWS Batch compute environments"
  assume_role_policy = data.aws_iam_policy_document.ecs_instance_trust.json

  tags = var.standard_tags
}

###############################################################################
# ATTACH THE AWS‑MANAGED POLICIES
###############################################################################
data "aws_iam_policy" "ecs_EC2ContainerServiceforEC2Role" {
  name = "AmazonEC2ContainerServiceforEC2Role"
}

data "aws_iam_policy" "ecs_EC2ReadOnlyAccess" {
  name = "AmazonEC2ReadOnlyAccess"
}

data "aws_iam_policy" "ecs_CloudWatchAgentServerPolicy" {
  name = "CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_EC2ContainerServiceforEC2Role" {
  role       = aws_iam_role.ecs_instance.name
  policy_arn = data.aws_iam_policy.ecs_EC2ContainerServiceforEC2Role.arn
}

resource "aws_iam_role_policy_attachment" "ecs_EC2ReadOnlyAccess" {
  role       = aws_iam_role.ecs_instance.name
  policy_arn = data.aws_iam_policy.ecs_EC2ReadOnlyAccess.arn
}

resource "aws_iam_role_policy_attachment" "ecs_CloudWatchAgentServerPolicy" {
  role       = aws_iam_role.ecs_instance.name
  policy_arn = data.aws_iam_policy.ecs_CloudWatchAgentServerPolicy.arn
}
