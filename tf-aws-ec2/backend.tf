terraform {
  backend "s3" {
    bucket = "terraform-eks-cicd-hmurafique"
    key    = "jenkins/terraform.tfstate"
    region = "us-east-1"
  }
}
