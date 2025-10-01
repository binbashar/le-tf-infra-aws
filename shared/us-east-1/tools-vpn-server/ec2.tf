#
# EC2 Pritunl OpenVPN
#
module "terraform-aws-basic-layout" {
  source = "github.com/binbashar/terraform-aws-ec2-basic-layout.git?ref=v0.3.35"
  prefix = var.prefix
  name   = var.name

  aws_ami_os_id          = var.aws_ami_os_id
  aws_ami_os_owner       = var.aws_ami_os_owner
  tag_approved_ami_value = var.tag_approved_ami_value

  instance_type = var.instance_type
  vpc_id        = data.terraform_remote_state.vpc.outputs.vpc_id

  subnet_id                   = data.terraform_remote_state.vpc.outputs.public_subnets[0]
  associate_public_ip_address = var.associate_public_ip_address
  key_pair_name               = data.terraform_remote_state.keys.outputs.aws_key_pair_name
  ebs_optimized               = var.ebs_optimized
  monitoring                  = var.monitoring
  user_data_base64            = base64encode(local.user_data)
  enable_ssm_access           = var.enable_ssm_access

  root_block_device = [
    {
      volume_type = "gp2"
      volume_size = 16
      encrypted   = true
    },
  ]

  security_group_rules = [
    {
      from_port = 22, # SSH
      to_port   = 22,
      protocol  = "tcp",
      cidr_blocks = [
        # SSH access is allowed while connected to the VPN
        data.terraform_remote_state.vpc.outputs.vpc_cidr_block,
        #
        # NOTE: During the first installation, it is convenient to add your
        #       IP here (unless you are planning to use SSM instead).
        #
      ],
      description = "Allow SSH"
    },
    # {
    #   from_port = 9100, # Prometheus Node Exporter
    #   to_port   = 9100,
    #   protocol  = "tcp",
    #   cidr_blocks = [
    #     data.terraform_remote_state.vpc.outputs.vpc_cidr_block,
    #     data.terraform_remote_state.vpc-dr.outputs.vpc_cidr_block
    #   ],
    #   description = "Allow Prometheus NodeExporter"
    # },
    {
      from_port = 80, # Pritunl VPN Server Letsencrypt http challenge
      to_port   = 80,
      protocol  = "tcp",
      cidr_blocks = [
        # Access to Pritunl Admin Web from the VPN is allowed, just for TLS redirection
        data.terraform_remote_state.vpc.outputs.vpc_cidr_block,
        # NOTE: Opening this port is required about every 90 days in order to
        #       renew the Let's Encrypt certificate used for TLS.
        # "0.0.0.0/0",
      ],
      description = "Allow Pritunl HTTP UI"
    },
    {
      from_port = 443, # Pritunl VPN Server UI
      to_port   = 443,
      protocol  = "tcp",
      cidr_blocks = [
        # Access to Pritunl Admin Web from the VPN is allowed
        data.terraform_remote_state.vpc.outputs.vpc_cidr_block,
        # NOTE: Opening port 443 is usually required for onboarding new users,
        #       so they can set up their pin code and OTP. A more secure option
        #       is to whitelist each user's IP.
        #"0.0.0.0/0",
      ],
      description = "Allow Pritunl HTTPS UI"
    },
    {
      # NOTE: this must match the port of the server that you created via
      #       Pritunl Admin Web
      from_port   = 15255, # Pritunl VPN Server public UDP service ports -> pritunl.server.admin org
      to_port     = 15256, # Pritunl VPN Server public UDP service ports -> pritunl.server.devops org
      protocol    = "udp",
      cidr_blocks = ["0.0.0.0/0"],
      description = "Allow Pritunl Service"
    }
  ]

  dns_records_internal_hosted_zone = [{
    zone_id = data.terraform_remote_state.dns.outputs.aws_internal_zone_id,
    name    = "vpn.aws.binbash.com.ar",
    type    = "A",
    ttl     = 300
  }]

  # ---------------------------------------------------------------------------
  # IMPORTANT!
  # ---------------------------------------------------------------------------
  # Exposing the Pritunl Web Admin is required from time to time because of
  # the following tasks.
  # ---------------------------------------------------------------------------
  # 1.Renew LetsEncrypt private url cert (every 90 days)
  #    a. must temporally open port 80 to the world (line 52)
  #    b. must temporally open port 443 to the world (line 59)
  #    c. must uncomment public DNS record block (lines 105-112)
  #    d. make apply
  #    e. connect to the VPN and ssh to the Pritunl EC2
  #    f. run '$sudo pritunl reset-ssl-cert'
  #    g. force SSL cert update (manually via UI or via API call)
  #       in the case of using the UI, set the "Lets Encrypt Domain" field with the vpn domain and click on save
  #    h. rollback steps a,b & c + make apply
  #
  # 2.New users setup (to view profile links -> PIN reset + OTP / uri link for Pritunl Client import).
  #    a. must open port 443 (line 60)
  #    b. must uncomment public DNS record block (lines 105-112)
  #    c. share new user setup links security (eg: LastPass / Bitwarden)
  #    d. rollback a. step
  #    e. re-comment block from step b.
  #

  /*  dns_records_public_hosted_zone = [{
    zone_id = data.terraform_remote_state.dns.outputs.aws_public_zone_id,
    name    = "vpn.aws.binbash.com.ar",
    type    = "A",
    ttl     = 300
  }]*/

  tags = local.tags
}
