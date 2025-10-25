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
   -systemctl jenkins.service status
4. Paste the password into the "Administrator password" field on the Jenkins setup page and click "Continue".  
5. Follow the on-screen instructions to complete the Jenkins setup - install suggested plugins, create the first admin user, and configure the instance settings.
6. Once the setup is complete, you will be redirected to the Jenkins dashboard where you can start creating and managing your Jenkins jobs.
7. Under mangae jenkins go to plugins install aws credentials pipeline: aws steps.
8. Under manage jenkins go to credentials then global and add aws credentials with access key and secret key(we anohter option here thats why we insyalled aws credentials plugin).
   - need to add aws access key and secret key with admin permission.
9.  We need to configure Terraform for our jenkins server so go under manage jenkins then plugin and install terraform plugin.
10. Go to tools then add terraform then install directory /usr/bin/terraform. 

# Create a Jenkins Pipeline for Infrastructure Deployment.
1. In the Jenkins dashboard, click on "New Item".
2. Enter a name for your pipeline (e.g., "Infrastructure=Job") and select "Pipeline" as the project type. Click "OK".
3. In the pipeline configuration page, scroll down to the "Pipeline" section.
4. Select "Pipeline script" from the "Definition" dropdown menu.
5. Copy and paste the following pipeline script into the script text area:jenkins-pipeline.
6. Then apply and save.
7. Go to plugiun and install pipeline:stage view plugin.
8. Now, click on "Build with Parameters" to start the pipeline.
9. SET ENVIRENMENT NAME dev and TERRAFORMA ACTION apply then click on build.

# Create a Jump Host to access the private EC2 instances
1. Launch a new EC2 instance in the public subnet of your VPC to act as a jump host.
2. Choose an Amazon Machine Image (AMI) - Select " Ubuntu Server 22.04 LTS (HVM), SSD Volume Type".
3. Choose an Instance Type - Select "t2.micro" (eligible for free tier).
4. Proceed without key pair for now beause we will use SSM to connect.
5. Chose your vpc.
6. Select the public subnet.
7. Under advanced details, Select UAM profile with admin access.
8. In user data, add the following script to install necessary tools:tools-install-jump.sh.
9. then review and launch the instance.
10. Once the instance is running, connect to it using Session Manager.

# Setup k8 server in jump host.
1. After connecting to the jump host instance, switch to the root user by typing `sudo su -`.
2. Install kubectl by following the official Kubernetes documentation or by running the following commands:
   ```
   curl -LO "https://dl.k8s.io/release/$(curl -L -s
# Create a Jenkins Pipeline for MERN Application Deploymen https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
   chmod +x kubectl
   mv kubectl /usr/local/bin/
   ```
3. Verify the installation by running `kubectl version --client`.

# To create a load balancer.
1. we need an iamserviceaccount with necessary permission.
2. install helm on jump host.

#create argocd namespace
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.4.7/manifests/install.yaml
to access argocd server from outside we need to:
-change the service type from clusterIP to LoadBalancer:
  kubectl edit svc argocd-server -n argocd     
-Copy dns name and paste it in browser.   
-get the initial admin password:
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

# COnfigure sonarQube in jenkins(Currentlt running in jenkins server itself)      
1. on jenkins server type docker ps to check the running containers.
2. sonarQube is running in docker container on port 9000.
3. type curl ipconfig.me to get public ip of jenkins server.
4. Open your web browser and navigate to `http://<jenkins-server-public-ip>:9000`.
5. Login with default credentials (username: admin, password: admin).
6. Follow the video instructions to configure sonarQube with jenkins and project repository..


# Setup Argocd for Project.
1. Create new repo using https.
2. type -git,project - default,repo url- your repo url and then connect.
3. Create database first then create backend then frontend.
  first we deploy databaswe on k8 cluster using argocd.
   -pv and pvc will be created for database so that data will be persistent.
   -Create a name space database before deploying the application.
   kubectl create ns three-tier
   -Database application name: three-tier-database,project: default, repo url: your repo url, path: kubernetes-manifeats-file/database, cluster url: default, namespace: three-tier.
   thrn click on create.
4. similarly create backend application.
  application name: three-tier-database,project: default, repo url: your repo url, path: kubernetes-manifeats-file/backend, cluster url: default, namespace: three-tier.
5. similarly create frontend application.
  application name: three-tier-frontend,project: default, repo url: your repo url, path: kubernetes-manifeats-file/frontend, cluster url: default, namespace: three-tier.
6. Since this is still clusterIP type service, we need to create a load balancer to access the frontend application from outside.
7. We will create a new application for load balancer.
  application name: three-tier-ingress ,project: default, repo url: your repo url, path: kubernetes-manifeats-file/load-balancer, cluster url: default, namespace: three-tier.
8. Now, we can access the frontend application using the load balancer DNS name.
9. To get the load balancer DNS name, go to AWS Management Console > EC2 Dashboard > Load Balancers.
10. Copy the DNS name of the load balancer, we cant access the frontend application using this DNS name in the browser.
11. We need to map our domain name to this load balancer DNS name using Route 53.
12. Go to AWS Management Console > Route 53 > Hosted Zones.

# Prometheus and Grafana Setup for Monitoring
1. Install Prometheus and Grafana on your Kubernetes cluster using Helm charts on the jump host.
2. We will set up the Monitoring for our EKS Cluster. We can monitor the Cluster Specifications and other necessary things.

We will achieve the monitoring using Helm
Add the Prometheus repo by using the command below

helm repo add stable https://charts.helm.sh/stable
Press enter or click to view image in full size

Install the Prometheus

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/prometheus
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm install grafana grafana/grafana
Press enter or click to view image in full size

3. We need to expose prometheus and grafana server using load balancer to access from outside.
4. currently if you do kubectl get svc you will see both prometheus and grafana service type is clusterIP and port 80.
5. To change the service type to load balancer we will use the below commands:
   kubectl edit svc prometheus-server
   kubectl edit svc grafana
6. Change the service type from ClusterIP to LoadBalancer and save the file.
7. Now copy load balancers dns and paste it in browser to access prometheus and grafana server.

   