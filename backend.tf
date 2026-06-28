terraform {
    backend "s3" {
        region = "ap-south-1"
        bucket = "kailash.project.monobucket"
        key = "prod/terraform.tfstate"
    }
}