# terraform {
#   backend "remote" {  
#     hostname="app.terraform.io"  
#     organization = "lancheholdings" 
#     workspaces {
#       prefix = "prodxcloud" 
#     }
#   }
# }

terraform {
  backend "s3" {
    bucket         = "django-app-6"
    region         = "us-east-1"
    key            = "state/terraform.tfstate"
    dynamodb_table = "use_lockfile = true"
    encrypt        = true
  }
}


