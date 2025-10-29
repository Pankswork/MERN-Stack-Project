## MERN STACK PROJECT

# Create a EC2 Instance for Jenkins server(Acts as master and slave both)

1. Log in to your AWS Management Console.
2. Navigate to the EC2 Dashboard.   
3. Click on "Launch Instance".
4. Choose an Amazon Machine Image (AMI) - Select " Ubuntu Server 22.04 LTS (HVM), SSD Volume Type".
5. Choose an Instance Type - Select "myi-flex.large" (eligible for free tier).
6. Proceed without key pair for now beause we will use SSM to connect.
7. Create security group - allow jenkins port 8080 and sonarwube port 9000.
8. Create IAM Role with SSM and attach it to the instance give only necessary permission, as of now iam giving AmazonSSMFullAccess for testing purpose.
   -Go to IAM → Roles → Create role
    Trusted entity type → Choose AWS Service
    Use case → Select EC2 → Next
    Attach these policies:
    AmazonSSMManagedInstanceCore (for SSM access)
    AdministratorAccess (for full permissions)
    Click Next, give it a name like:
    Click Create role.
9. We are adding userdata: tools-install.sh.
   -jdk : prerequisite for jenkins.
   -jenkins : to setup jenkins server.
   -docker : for build and push docker images.
   -terraform : for infrastructure as code.
   -awscli : to interact with aws services.
   -not installing sonarqube directly instead using docker image for sonarqube.
   -trivy : for scanning docker images.
10. Review and Launch the instance.
11. Once the instance is running, click on connect and follow the instructions to connect using Session Manager.

# Connect to the instance using Session Manager

1. Go to EC2 Dashboard.
2. type sudo su Ubuntu
3. type htop to check the system performance.
4. CHeck the installed tools: git, nodejs, npm, mongodb, nginx, docker, docker-compose, jenkins.
5. Dont close SSM now we will setup jenkins server.
 
# login to jenkins

1. Open your web browser and navigate to `http://<your-ec2-public-ip>:8080`. 
2. For login to jenkins you will be needing a password.
3. To retrieve the initial admin password type:
```bash
   -systemctl jenkins.service status
```
4. Paste the password into the "Administrator password" field on the Jenkins setup page and click "Continue".  
5. Follow the on-screen instructions to complete the Jenkins setup - install suggested plugins, create the first admin user, and configure the instance settings.
6. Once the setup is complete, you will be redirected to the Jenkins dashboard where you can start creating and managing your Jenkins jobs.
7. Under mangae jenkins go to plugins install aws credentials pipeline: aws steps.
8. Under manage jenkins go to credentials then global and add aws credentials with access key and secret key(we anohter option here thats why we insyalled aws credentials plugin).
   - need to add aws access key and secret key with admin permission.
9.  We need to configure Terraform for our jenkins server so go under manage jenkins then plugin and install terraform plugin.
10. Go to tools then add terraform then install directory /usr/bin/terraform.
11. Need to Create S3 bucket and dynamodb manually:

```bash
   - aws s3api create-bucket \
  --bucket mern-stack-panks \
  --region us-east-1
  ```

```bash
  aws dynamodb create-table \
  --table-name Lock-Files \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
  ```

# Create a Jenkins Pipeline for Infrastructure Deployment.

1. In the Jenkins dashboard, click on "New Item".
2. Enter a name for your pipeline (e.g., "Infrastructure=Job") and select "Pipeline" as the project type. Click "OK".
3. In the pipeline configuration page, scroll down to the "Pipeline" section.
4. Select "Pipeline script" from the "Definition" dropdown menu.
5. Copy and paste the following pipeline script into the script text area:jenkins-pipeline.
6. Then apply and save.
7. Go to plugiun and install pipeline:stage view plugin.
8. Now, click on "Build with Parameters" to start the pipeline.
9. Once the pipeline is completed SET ENVIRENMENT NAME dev and TERRAFORMA ACTION apply then click on build.

# Create a Jump Host to access the private EC2 instances

1. Launch a new EC2 instance in the public subnet of your VPC to act as a jump host.
2. Choose an Amazon Machine Image (AMI) - Select " Ubuntu Server 22.04 LTS (HVM), SSD Volume Type".
3. Choose an Instance Type - Select "myi-flex.large" (eligible for free tier).
4. Proceed without key pair for now beause we will use SSM to connect.
5. Chose your vpc.
6. Select the new vpc and public subnet.
7. Under advanced details, Select UAM profile with admin access.
8. In user data, add the following script to install necessary tools:tools-install-jump.sh.
9. then review and launch the instance.
10. Once the instance is running, connect to it using Session Manager.

# Setup k8 server in jump host.

1. After connecting to the jump host instance, switch to the root user by typing `sudo su ubuntu`.
2. Install kubectl by following the official Kubernetes documentation or by running the following commands:

```bash
   curl -LO "https://dl.k8s.io/release/$(curl -L -s
    Create a Jenkins Pipeline for MERN Application Deploymen https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
   chmod +x kubectl
   mv kubectl /usr/local/bin/
   ```

3. Verify the installation by running `kubectl version --client`.
4. Run this command to update kubeconfig:

```bash
   aws eks update-kubeconfig --name dev-ap-medium-eks-cluster --region us-east-1
   ```

5. Do aws configure and credentials.
6. Do kubectl get nodes to check.


# To create a load balancer.
   For ingress controller to create a LB meaning use aws resource we need to have this.
1. we need an iamserviceaccount with necessary permission.(change account and cluster name)

   Fethcing policy:-
```bash
   curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.5.4/docs/install/iam_policy.json

   aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam_policy.json

   eksctl create iamserviceaccount --cluster=dev-ap-medium-eks-cluster --namespace=kube-system --name=aws-load-balancer-controller --role-name AmazonEKSLoadBalancerControllerRole --attach-policy-arn=arn:aws:iam::668227158023:policy/AWSLoadBalancerControllerIAMPolicy --approve --region=us-east-1 --override-existing-serviceaccounts
```

2.  Helm is required to deploy ingress controller and argocd.
    Add helm repo and install:

```bash
      sudo snap install helm --classic
      helm repo add eks https://aws.github.io/eks-charts
      helm repo update eks
      helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=dev-ap-medium-eks-cluster --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller
      ```

3. to check pods are running or not:

```bash
      kubectl get deployment -n kube-system aws-load-balancer-controller
```

# create argocd namespace

1. Create namespace:

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.4.7/manifests/install.yaml
```

2. To access argocd server from outside we need to:

   -change the service type from clusterIP to LoadBalancer:
```bash
      kubectl edit svc argocd-server -n argocd  
```   
   -Copy dns name and paste it in browser.   
   -get the initial admin password:
```bash
      kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```
3. User is admin and password you will get from above command.

# COnfigure sonarQube in jenkins(Currentlt running in jenkins server itself)   

1. On jenkins server type docker ps to check the running containers.
2. sonarQube is running in docker container on port 9000.
3. type curl ifconfig.me to get public ip of jenkins server.
4. Open your web browser and navigate to `http://<jenkins-server-public-ip>:9000`.
5. Login with default credentials (username: admin, password: admin).
6. Follow the video instructions to configure sonarQube with jenkins and project repository..

# Setup Sonarqube

1. We have to Connect jenkins to sonarqube so we have to create a token first.
2. Go administraion>security>user>below token>update token.
3. Go to configuration>webhook>create>name=jenkins,url:http://54.89.127.138:8080/sonarqube-webhook/(webhook to to let external party know that analysis is done)
4. Now to to create project, First we will create for frontend: go to project>manually>name and key =frontend and branch=main.
5. Analyze your project> give your exixting token>others>linux>copy the code and save it.
5. Now for backend, do the same and save the code.
6. Save sonarqube token, aws account id github in jenkins.
  kind=secret text ,ID=sonar-token
  kind=secret text ,ID=ACCOUNT_ID
  kind=secret text ,ID=github

# Create ECR repo for frontend and backend repo

1. Go to ECR >create>private>frontend.
2. Same for backend.
3. Go jenkins credentials create credentials secret text > secret=frontend>ID=ECR_REPO1.
4. secret text > secret=backend>ID=ECR_REPO2.
5. user and password >user=pankswork>ID=GITHUB-APP
6. Go to plugins and install Docekr,Docker commons,docker pipeline and docker api,sonarqube scanner,nodejs,owasp dependency check.
7. Go to Tools>nodejs,install auto>DP-Check,install-auto git,docker,install auto docker.com>sonar-scanner,install-auto
8. Connect webhook with jenkins, go to system >sonarqube install>sonar-server,http://54.89.127.138:9000,select credentials for sonar then apply ans save.

# create Jenkins Frontend and backend pipelines.

1. New item >Three-tier-frontend>pipeline>copy jenkinsfile-frontend
2. New item >Three-tier-frontend>pipeline>copy jenkinsfile-frontend

# Setup Argocd for Project.

1. Create new repo using https.
2. type -git,project - default,repo url- your repo url and then connect.
3. Create database first then create backend then frontend.
  first we deploy database on k8 cluster using argocd.
   -pv and pvc will be created for database so that data will be persistent.
   -Create a namespace database before deploying the application.
```bash   
    kubectl create ns three-tier
```
   -Database application name: three-tier-database,project: default, repo url: your repo url, path: kubernetes-manifeats-file/database, cluster url: default, namespace: three-tier.
   thrn click on create.
4. similarly create backend application.
  application name: three-tier-database,project: default, repo url: your repo url, path: kubernetes-manifeats-file/backend, cluster url: default, namespace: three-tier.
   (run this command:kubectl create secret docker-registry ecr-registry-secret \
  --docker-server=https://668227158023.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region us-east-1) \
  --namespace=three-tier
)
5. similarly create frontend application.
  application name: three-tier-frontend,project: default, repo url: your repo url, path: kubernetes-manifeats-file/frontend, cluster url: default, namespace: three-tier.
6. Since this is still clusterIP type service, we need to create a load balancer to access the frontend application from outside.
7. We will create a new application for load balancer.
  application name: three-tier-ingress ,project: default, repo url: your repo url, path: kubernetes-manifeats-file/load-balancer, cluster url: default, namespace: three-tier.

  (do this if fails:
  Step 1: Create a JSON policy file
  Run this:
```bash
cat > alb-controller-policy.json <<'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "acm:DescribeCertificate",
        "acm:ListCertificates",
        "acm:GetCertificate",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:Describe*",
        "ec2:RevokeSecurityGroupIngress",
        "elasticloadbalancing:AddTags",
        "elasticloadbalancing:CreateListener",
        "elasticloadbalancing:CreateLoadBalancer",
        "elasticloadbalancing:CreateRule",
        "elasticloadbalancing:CreateTargetGroup",
        "elasticloadbalancing:DeleteListener",
        "elasticloadbalancing:DeleteLoadBalancer",
        "elasticloadbalancing:DeleteRule",
        "elasticloadbalancing:DeleteTargetGroup",
        "elasticloadbalancing:DeregisterTargets",
        "elasticloadbalancing:Describe*",
        "elasticloadbalancing:ModifyListener",
        "elasticloadbalancing:ModifyLoadBalancerAttributes",
        "elasticloadbalancing:ModifyRule",
        "elasticloadbalancing:ModifyTargetGroup",
        "elasticloadbalancing:ModifyTargetGroupAttributes",
        "elasticloadbalancing:RegisterTargets",
        "elasticloadbalancing:SetSecurityGroups",
        "elasticloadbalancing:SetSubnets",
        "elasticloadbalancing:SetIpAddressType",
        "elasticloadbalancing:DescribeListenerAttributes"
      ],
      "Resource": "*"
    }
  ]
}
EOF
```

Step 2: Attach this policy inline to your role

Run this (replace the ARN with your own — yours is already correct):
```bash
aws iam put-role-policy \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --policy-name ALBControllerFullAccess \
  --policy-document file://alb-controller-policy.json
```
)
8. Now, we can access the frontend application using the load balancer DNS name.
9. To get the load balancer DNS name, go to AWS Management Console > EC2 Dashboard > Load Balancers.
10. type kubectl get ingress -n three-tier
11. And paste the address in the browser.

# Prometheus and Grafana Setup for Monitoring

1. Install Prometheus and Grafana on your Kubernetes cluster using Helm charts on the jump host.
2. We will set up the Monitoring for our EKS Cluster. We can monitor the Cluster Specifications and other necessary things.

We will achieve the monitoring using Helm:
Add the Prometheus repo by using the command below
```bash
helm repo add stable https://charts.helm.sh/stable
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/prometheus
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm install grafana grafana/grafana
```
3. We need to expose prometheus and grafana server using load balancer to access from outside.
4. currently if you do kubectl get svc you will see both prometheus and grafana service type is clusterIP and port 80.
5. To change the service type to load balancer we will use the below commands:
```bash
   kubectl edit svc prometheus-server
   kubectl edit svc grafana
```
6. Change the service type from ClusterIP to LoadBalancer and save the file.
7. Now copy load balancers dns and paste it in browser to access prometheus and grafana server.

## IMAGES

# Jenkins:

<img width="1894" height="1063" alt="Screenshot 2025-10-28 035458" src="https://github.com/user-attachments/assets/b675d40a-ba96-4575-9e97-5a9ac96194b6" />

<img width="1885" height="1059" alt="Screenshot 2025-10-28 035641" src="https://github.com/user-attachments/assets/5b70953b-5e13-4c3c-81f4-580538bfd52a" />

<img width="1898" height="1044" alt="Screenshot 2025-10-28 035758" src="https://github.com/user-attachments/assets/bfbb3fdf-ee18-49df-858d-d11e127eede2" />

# ArgoCD:


<img width="1907" height="1051" alt="Screenshot 2025-10-28 035956" src="https://github.com/user-attachments/assets/7783159a-cefe-4924-9f5d-addd3340d492" />

<img width="1905" height="1062" alt="Screenshot 2025-10-28 035905" src="https://github.com/user-attachments/assets/1e1915bf-2ad6-4e39-a410-b734c71883af" />

#Sonarqube

<img width="1908" height="1060" alt="Screenshot 2025-10-28 035823" src="https://github.com/user-attachments/assets/f14db11c-d5bb-4c02-9b66-ead1e501d28e" />

# Todo-App

<img width="1887" height="1060" alt="Screenshot 2025-10-28 040102" src="https://github.com/user-attachments/assets/f77c8f09-3ff0-4783-bd8a-860e99c7d2e6" />

<img width="1897" height="1053" alt="Screenshot 2025-10-28 040019" src="https://github.com/user-attachments/assets/07e1e08d-1710-4061-b13f-9a49881a281d" />

