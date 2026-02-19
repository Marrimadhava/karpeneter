# 🚀 Karpenter Installation on Amazon EKS (Terraform + YAML)

## 📌 Project Overview

This project demonstrates how to install and configure **Karpenter** on
an **Amazon EKS cluster** using:

-   Terraform (for controller installation)
-   IAM Roles (IRSA + Node Role)
-   EC2NodeClass & NodePool
-   aws-auth ConfigMap integration

This setup enables dynamic node provisioning based on pending pods.

------------------------------------------------------------------------

## 🏗 Architecture Flow

1.  Pod becomes **Pending**
2.  Karpenter detects unschedulable pod
3.  Launches EC2 instance dynamically
4.  Node joins cluster
5.  Pod gets scheduled automatically

------------------------------------------------------------------------

# 📋 Prerequisites

-   Existing Amazon EKS cluster
-   kubectl configured
-   Terraform installed
-   AWS CLI configured
-   OIDC enabled for EKS cluster

------------------------------------------------------------------------

# 🔹 Step 1: Get OIDC Provider

``` bash
aws eks describe-cluster \
  --name <your-cluster-name> \
  --region <your-region> \
  --query "cluster.identity.oidc.issuer" \
  --output text
```

------------------------------------------------------------------------

# 🔹 Step 2: Tag Subnets & Security Groups

Add the following tag to:

-   Private Subnets
-   Cluster Security Group

Key = karpenter.sh/discovery\
Value = `<CLUSTER_NAME>`{=html}

------------------------------------------------------------------------

# 🔹 Step 3: Create IAM Roles

## 🟢 Karpenter Controller Role

Role Name: KarpenterControllerRole-`<your-cluster-name>`{=html}

### Trust Relationship (IRSA)

``` json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<AccountID>:oidc-provider/oidc.eks.<your-region>.amazonaws.com/id/<OIDC_ID>"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.<your-region>.amazonaws.com/id/<OIDC_ID>:aud": "sts.amazonaws.com",
          "oidc.eks.<your-region>.amazonaws.com/id/<OIDC_ID>:sub": "system:serviceaccount:kube-system:karpenter"
        }
      }
    }
  ]
}
```

Attach the required controller policy (EC2, IAM, EKS, Pricing, SSM, SQS
permissions).

------------------------------------------------------------------------

## 🟢 Karpenter Node Role

Role Name: KarpenterNodeRole-`<your-cluster-name>`{=html}

### Trust Relationship

``` json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

### Attach AWS Managed Policies

-   AmazonEC2ContainerRegistryReadOnly\
-   AmazonEKS_CNI_Policy\
-   AmazonEKSWorkerNodePolicy\
-   AmazonSSMManagedInstanceCore

------------------------------------------------------------------------

# 🔹 Step 4: Update aws-auth ConfigMap

``` yaml
- groups:
  - system:bootstrappers
  - system:nodes
  rolearn: arn:aws:iam::<AccountID>:role/KarpenterNodeRole-<your-cluster-name>
  username: system:node:{{EC2PrivateDNSName}}
```

------------------------------------------------------------------------

# 🔹 Step 5: Install Karpenter via Terraform

``` bash
terraform init
terraform plan
terraform apply
```

------------------------------------------------------------------------

# 🔹 Step 6: Apply NodeClass & NodePool

``` bash
kubectl apply -f ec2nodeclass.yaml
kubectl apply -f nodepool.yaml
```

------------------------------------------------------------------------

# 🔍 Verification Steps

### ✅ Check EC2NodeClass

``` bash
kubectl get ec2nodeclass
```

Expected Output:

NAME READY AGE\
default True 7h44m

------------------------------------------------------------------------

### ✅ Check NodeClaims

``` bash
kubectl get nodeclaims
```

------------------------------------------------------------------------

### ✅ Test Auto Scaling

1.  Increase replicas in a deployment
2.  Pods go Pending
3.  Karpenter creates new EC2 nodes
4.  Pods get scheduled automatically

------------------------------------------------------------------------

# 📂 Project Structure

. ├── karpenter-install.tf\
├── ec2nodeclass.yaml\
├── nodepool.yaml\
└── README.md

------------------------------------------------------------------------

# 🎯 Key Benefits

-   ⚡ Fast node provisioning
-   💰 Cost optimized (Spot / On-demand mix)
-   🔄 Automatic scale up & down
-   🚀 Infrastructure as Code
-   🔐 Secure IRSA integration

------------------------------------------------------------------------

# 👨‍💻 Author

DevOps \| AWS \| Kubernetes \| Terraform\
Production-grade autoscaling implementation using Karpenter.
