AWS CLI/SDK configured.
Terraform installed and initialized.
Run terraform init to initialize the configuration.
Run terraform validate and terraform fmt to check if any syntax issue or indentation issue.
Run terraform plan to check whats will be deploy.
Run terraform apply to create the resources.

After deployment, you can access your ECS service via the ALB’s DNS name (which can be found under the ALB’s details in the AWS Management Console).
