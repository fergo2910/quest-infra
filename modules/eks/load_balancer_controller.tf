data "aws_iam_policy_document" "aws_load_balancer_controller_trust_policy" {
  count = local.addon_create_roles["aws-load-balancer-controller"] ? 1 : 0

  statement {
    sid    = "EKSAWSLoadBalancerControllerTrustPolicyStatement"
    effect = "Allow"

    actions = [
      "sts:AssumeRoleWithWebIdentity",
    ]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.oidc[0].arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${aws_iam_openid_connect_provider.oidc[0].url}:sub"

      values = [
        local.addon_fq_service_account_names["aws-load-balancer-controller"]
      ]
    }
  }
}

resource "aws_iam_role" "aws_load_balancer_controller_role" {
  count = local.addon_create_roles["aws-load-balancer-controller"] ? 1 : 0

  name               = "${var.environment}-EksAWSLoadBalancerControllerRole"
  assume_role_policy = data.aws_iam_policy_document.aws_load_balancer_controller_trust_policy[0].json
}

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller_role_ingress_controller_policy" {
  count = local.addon_create_roles["aws-load-balancer-controller"] && local.addon_attach_policies_to_irsa["ingress-controller"] ? 1 : 0

  policy_arn = aws_iam_policy.ingress_controller_policy[count.index].arn
  role       = aws_iam_role.aws_load_balancer_controller_role[count.index].name
}

resource "aws_iam_policy" "ingress_controller_upgrade_policy" {
  count = local.addon_create_policies["ingress-controller-upgrade"] ? 1 : 0

  name        = "${var.environment}-EksIngressControllerUpgrade"
  description = "Allows additional permissions required by AWS Load Balancer Controller"
  policy      = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Effect": "Allow",
          "Action": [
              "ec2:CreateTags",
              "ec2:DeleteTags"
          ],
          "Resource": "arn:aws:ec2:*:*:security-group/*",
          "Condition": {
              "Null": {
                  "aws:ResourceTag/ingress.k8s.aws/cluster": "false"
              }
          }
      },
      {
          "Effect": "Allow",
          "Action": [
              "elasticloadbalancing:AddTags",
              "elasticloadbalancing:RemoveTags",
              "elasticloadbalancing:DeleteTargetGroup"
          ],
          "Resource": [
              "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
              "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
              "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
          ],
          "Condition": {
              "Null": {
                  "aws:ResourceTag/ingress.k8s.aws/cluster": "false"
              }
          }
      }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller_role_ingress_controller_upgrade_policy" {
  count = local.addon_attach_policies_to_irsa["ingress-controller-upgrade"] ? 1 : 0

  policy_arn = aws_iam_policy.ingress_controller_upgrade_policy[count.index].arn
  role       = aws_iam_role.aws_load_balancer_controller_role[count.index].name
}
