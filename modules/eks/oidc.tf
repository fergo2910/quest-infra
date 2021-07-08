# --------------------------------------------------------------------
# OpenID Connect Provider
# --------------------------------------------------------------------

resource "aws_iam_openid_connect_provider" "oidc" {
  count = var.enable_irsa ? 1 : 0

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster_issuer.certificates.0.sha1_fingerprint]
  url             = aws_eks_cluster.masters.identity.0.oidc.0.issuer
}

data "tls_certificate" "cluster_issuer" {
  url = aws_eks_cluster.masters.identity.0.oidc.0.issuer
}
