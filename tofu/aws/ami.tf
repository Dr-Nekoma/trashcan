# To test if a particular set of filters works:
# aws ec2 describe-images --owners 427812963091  --filter 'Name=name,Values=nixos/25.05*' 'Name=architecture,Values=x86_64' --query 'sort_by(Images, &CreationDate)' --region us-east-1

data "aws_ami" "nixos_amd" {
  owners      = ["427812963091"]
  most_recent = true

  filter {
    name   = "name"
    values = ["nixos/${var.ami_version}*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_instance" "nixos_amd" {
  ami           = data.aws_ami.nixos_amd.id
  instance_type = var.instance_type
}
