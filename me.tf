provider "aws" {
 region = "ap-south-1"
 profile = "Anuska"
}

resource "aws_instance" "web" {
 ami = "ami-0447a12f28fddb066"
 instance_type = "t2.micro"
 key_name = "mykey111"
 security_groups = [ "launch-wizard-4" ]

connection {
 type = "ssh"
 user = "ec2-user"
 private_key = file("C:/Users/KIIT/Downloads/mykey111.pem")
 host = aws_instance.web.public_ip
 }
provisioner "remote-exec" {
 inline = [
 "sudo yum install httpd php git -y",
 "sudo systemctl restart httpd",
 "sudo systemctl enable httpd",
 ]
 }
tags = {
 Name = "HiiiEveryone1"
 }
}

resource "aws_ebs_volume" "ebs1" {
  availability_zone = aws_instance.web.availability_zone
  size              = 1

  tags = {
    Name = "Helloebs"
  }
}


resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = "${aws_ebs_volume.ebs1.id}"
  instance_id = "${aws_instance.web.id}"
  force_detach = true
}



output "myos_ip" {
    value = aws_instance.web.public_ip
}

resource "null_resource" "nulllocal2" {
	provisioner "local-exec" {
	command = "echo ${aws_instance.web.public_ip} > publicip.txt"
	}
}



resource "null_resource" "nullremote3" {

depends_on = [
    aws_volume_attachment.ebs_att,
  ]
  


  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/KIIT/Downloads/mykey111.pem")
    host     = aws_instance.web.public_ip
  }


provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4  /dev/xvdh",
      "sudo mount  /dev/xvdh  /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/anuskadass/anuskacloud.git /var/www/html/",
    ]
  }
}

resource "null_resource" "nulllocal1" {

depends_on = [
    null_resource.nullremote3,
  ]

provisioner "local-exec"{
command = "start firefox ${aws_instance.web.public_ip}"
}
}


resource "aws_s3_bucket" "kiitanubucket" {
  bucket = "myanubucket"
  acl    = "public-read"

  versioning {
	enabled = true
	}
}

locals {
    s3_origin_id ="s3Origin"
}
resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
    comment = "Some comment"
}


resource "aws_s3_bucket_object" "object" {
	bucket = aws_s3_bucket.kiitanubucket.bucket
	key    = "terraform.png"
	source = "C:/Users/KIIT/Downloads/terraform.png"
	etag = filemd5("C:/Users/KIIT/Downloads/terraform.png")
	acl="public-read"
}

resource "aws_cloudfront_distribution" "s3_today" {
 origin {
 domain_name = aws_s3_bucket.kiitanubucket.bucket_regional_domain_name
 origin_id = local.s3_origin_id
s3_origin_config {
	origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
}
 }
 enabled = true
 is_ipv6_enabled = true
 
 
default_cache_behavior {
 allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
 cached_methods = ["GET", "HEAD"]
 target_origin_id = local.s3_origin_id
 forwarded_values {
 query_string = false
 cookies {
 forward = "none"
 }
 }
 viewer_protocol_policy = "allow-all"
 min_ttl = 0
 default_ttl = 3600
 max_ttl = 86400
 }

restrictions {
	geo_restriction{
		restriction_type = "none"
	}
}

	viewer_certificate {
		cloudfront_default_certificate = true
	}
}

