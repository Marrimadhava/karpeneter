# ───────────────────────────────────────────────
# 1. Install / manage CRDs (always do this first)
# ───────────────────────────────────────────────
resource "helm_release" "karpenter_crd" {
  namespace        = "karpenter"
  create_namespace = true

  name       = "karpenter-crd"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter-crd"
  version    = "1.9.0"           # ← keep in sync with controller version

}

# ───────────────────────────────────────────────
# 2. Install Karpenter controller
# ───────────────────────────────────────────────
resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = true

  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = "1.9.0"           # ← desired version (bump both together)

  depends_on = [
    helm_release.karpenter_crd
  ]

  # ── Core settings ───────────────────────────────────────
  set {
    name  = "settings.clusterName"
    value = "var.cluster_name"   # ← or better: var.cluster_name
  }
  set {
    name  = "settings.clusterEndpoint"
    value = "data.aws_eks_cluster.this.endpoint"  #cluster endpoint, e.g. https://ABCD123456.gr7.us-east-1.eks.amazonaws.com
  }
  set {
    name  = "settings.interruptionQueue"
    value = "var.cluster_name"   # ← usually = clusterName
  }
  # ── IAM Roles for Service Accounts (IRSA) ──────────────
  set {
    name  = "serviceAccount.create"
    value = "true"
  }
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = var.karpenter_controller_role_arn  # ← ARN of the IAM role for Karpenter controller
  }
  # ── Node role / instance profile Karpenter uses ────────
  set {
    name  = "settings.aws.defaultInstanceProfile"
    value = var.karpenter_node_instance_profile  # ← Instance profile name for Karpenter nodes
  }
  # ── Controller resources (optional but good to set) ─────
  set {
    name  = "controller.resources.requests.cpu"
    value = "1"
  }
  set {
    name  = "controller.resources.requests.memory"
    value = "1Gi"
  }
  set {
    name  = "controller.resources.limits.cpu"
    value = "1"
  }
  set {
    name  = "controller.resources.limits.memory"
    value = "1Gi"
  }
}
