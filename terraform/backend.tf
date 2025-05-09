terraform {
  backend "s3" {
    bucket         = "myawsbucket1692"
    key            = "CI_CD_PROJECT/terraform.tfstate"
    region         = "ap-northeast-2"
    use_lockfile   = true   # S3 네이티브 잠금 활성화
    encrypt        = true
  }
}