# Stratos-studycase

Following AWS Best Practices for deploying EKS

Description, TBD

    Nodes will be deployed in the private subnets
    Load balancers will be deployed in the public subnets
    the EKS elastic interfaces will be deployed in dedicated private subnets ....


To create 2 test instacnes (one in Private & one in Public subnet)

export AWS_ACCESS_KEY_ID=''
export AWS_SECRET_ACCESS_KEY=''
export AWS_REGION='us-east-1'

Run

terraform init
terraform plan
terraform apply

Get the kubeconfig file

 aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw cluster_name)

Test

kubectl get nodes
