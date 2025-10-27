Problem Summary

Your AWS Load Balancer Controller (ALB controller) deployment on EKS was failing earlier — either with errors like

“Service account not found”

“Cannot reuse a name that is still in use”

Or it simply wasn’t getting the right IAM permissions.

That happens because the controller needs to assume a special IAM role via OIDC to create and manage AWS Load Balancers (ALB, NLB) for your Kubernetes Ingress/Service resources.

✅ Step-by-Step Fix Breakdown
Step 1: Identify the Node Role

We first needed to know what IAM role your nodes were using:

aws eks describe-nodegroup \
  --cluster-name dev-ap-medium-eks-cluster \
  --nodegroup-name dev-ap-medium-eks-cluster-on-demand-nodes \
  --query 'nodegroup.nodeRole' \
  --output text


✅ This showed:

arn:aws:iam::668227158023:role/dev-ap-medium-eks-cluster-nodegroup-role-9554


That’s your node IAM role, used by worker nodes.

Step 2: Check Attached Policies

We checked what permissions that node role had:

aws iam list-attached-role-policies \
  --role-name dev-ap-medium-eks-cluster-nodegroup-role-9554


✅ It already had:

AmazonEKSWorkerNodePolicy

AmazonEKS_CNI_Policy

AmazonEC2ContainerRegistryReadOnly

AmazonEBSCSIDriverPolicy

👉 These are fine for node operation, but not for load balancer control, which requires its own IAM role.

Step 3: Retrieve OIDC Provider

The AWS Load Balancer Controller needs an OIDC identity to map Kubernetes service accounts to IAM roles (IRSA):

aws eks describe-cluster \
  --name dev-ap-medium-eks-cluster \
  --query "cluster.identity.oidc.issuer" \
  --output text


✅ We got:

https://oidc.eks.us-east-1.amazonaws.com/id/EB2B9FC94EA3ACDD98B33C45F0EEF5C9


That’s your cluster’s unique OIDC endpoint.

Step 4: Verify IAM Role for ALB Controller

You already had:

aws iam get-role \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --query "Role.AssumeRolePolicyDocument" \
  --output json


✅ It showed the correct trust relationship, pointing to your OIDC provider and the right service account:

"Principal": {
  "Federated": "arn:aws:iam::<account-id>:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/EB2B9FC94EA3ACDD98B33C45F0EEF5C9"
},
"Condition": {
  "StringEquals": {
    "oidc.eks.us-east-1.amazonaws.com/...:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller"
  }
}


So the role setup was ✅ correct.

Step 5: Reinstall (or Upgrade) the Helm Chart

Earlier, when you ran:

helm install aws-load-balancer-controller ...


You got:

Error: cannot re-use a name that is still in use


That means the Helm release name aws-load-balancer-controller already existed.

✅ We fixed that by upgrading instead of reinstalling:

helm upgrade aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=dev-ap-medium-eks-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=us-east-1 \
  --set vpcId=$(aws eks describe-cluster --name dev-ap-medium-eks-cluster --query "cluster.resourcesVpcConfig.vpcId" --output text)


This command did two key things:

Reused the existing Helm release name, instead of creating a duplicate.

Ensured it pointed to your existing IAM service account (aws-load-balancer-controller) which already had the OIDC role attached.

✅ Result:

Release "aws-load-balancer-controller" has been upgraded. Happy Helming!
STATUS: deployed

Step 6: Verification

We confirmed successful deployment:

helm list -n kube-system


✅ Output:

aws-load-balancer-controller  deployed  v2.14.1


Then (optional, to verify pods):

kubectl get pods -n kube-system | grep aws-load-balancer


You should see something like:

aws-load-balancer-controller-xxxxx   1/1   Running