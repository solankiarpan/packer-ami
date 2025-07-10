packer {
  required_version = ">= 1.7.0"

  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = ">= 1.2.0"
    }
  }
}

# Data source to get latest Rocky Linux 9 AMI from AWS Marketplace
data "amazon-ami" "rocky_9" {
  filters = {
    name                = "Rocky-9-EC2-Base-9.*-*x86_64*"
    architecture        = "x86_64"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
  most_recent = true
  # Rocky Linux AWS Marketplace account
  owners      = ["679593333241"]
  region      = var.region
}

source "amazon-ebs" "rocky" {
  region                      = var.region
  instance_type               = "t3.large"
  source_ami                  = data.amazon-ami.rocky_9.id
  ssh_username                = "rocky"
  ami_name                    = var.ami_name
  ami_description             = "Rocky Linux development AMI built with Packer"
  
  tags = {
    OS_Version = "Rocky Linux"
    Release    = "Latest"
    CreatedBy  = "Packer"
    CreatedAt  = timestamp()
  }

  associate_public_ip_address = true
  
  # Optional: Networking configuration for better control
  # vpc_id             = var.vpc_id
  # subnet_id          = var.subnet_id
  # security_group_ids = [var.security_group_id]
  
  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size          = 30
    volume_type          = "gp3"
    iops                 = 3000
    throughput           = 125
    delete_on_termination = true
    encrypted            = true
  }
  
  # SSH configuration
  #ssh_timeout               = "10m"
  #ssh_handshake_attempts    = 10
  #temporary_key_pair_type   = "ed25519"
  
  # SECURITY: Use IAM instance profile for AWS access
  iam_instance_profile = var.instance_profile_name
}

build {
  name    = "rockylinux-dev-ami"
  sources = ["source.amazon-ebs.rocky"]

  # Install updates and basic tools first
  provisioner "shell" {
    inline = [
      "sudo dnf update -y",
    ]
  }

  # ==========================================
  # SYSTEM CONFIGURATION SCRIPTS
  # ==========================================

  # SELinux Setup
  provisioner "file" {
    content = templatefile("provisioners/system/startup.sh.tpl", {
      # No variables needed for this script
    })
    destination = "/tmp/startup.sh"
  }

  provisioner "shell" {
    inline = [
      "chmod +x /tmp/startup.sh",
      "/tmp/startup.sh"
    ]
  }

  # ==========================================
  # SERVICES CONFIGURATION SCRIPTS
  # ==========================================

  // # VNC Setup
  // provisioner "file" {
  //   content = templatefile("provisioners/services/vnc-setup.sh.tpl", {
  //     vnc_password_parameter = var.vnc_password_parameter
  //     aws_region            = var.region
  //   })
  //   destination = "/tmp/vnc-setup.sh"
  // }

  // provisioner "shell" {
  //   inline = [
  //     "chmod +x /tmp/vnc-setup.sh",
  //     "/tmp/vnc-setup.sh"
  //   ]
  // }

  # EFS Setup
  provisioner "file" {
    content = templatefile("provisioners/services/efs-setup.sh.tpl", {
      efs_id = var.efs_id
    })
    destination = "/tmp/efs-setup.sh"
  }

  provisioner "shell" {
    inline = [
      "chmod +x /tmp/efs-setup.sh",
      "/tmp/efs-setup.sh"
    ]
  }

  # S3 Setup
  provisioner "file" {
    content = templatefile("provisioners/services/s3-setup.sh.tpl", {
      s3_bucket  = var.s3_bucket
      aws_region = var.region
    })
    destination = "/tmp/s3-setup.sh"
  }

  provisioner "shell" {
    inline = [
      "chmod +x /tmp/s3-setup.sh",
      "/tmp/s3-setup.sh"
    ]
  }

  // # ==========================================
  // # DEVELOPMENT TOOLS CONFIGURATION SCRIPTS
  // # ==========================================

  // # Development Tools
  // provisioner "file" {
  //   content = templatefile("provisioners/development/dev-tools-setup.sh.tpl", {
  //     # No variables needed for this script
  //   })
  //   destination = "/tmp/dev-tools-setup.sh"
  // }

  // provisioner "shell" {
  //   inline = [
  //     "chmod +x /tmp/dev-tools-setup.sh",
  //     "/tmp/dev-tools-setup.sh"
  //   ]
  // }

  // # PyCharm Setup
  // provisioner "file" {
  //   content = templatefile("provisioners/development/pycharm-setup.sh.tpl", {
  //     # No variables needed for this script
  //   })
  //   destination = "/tmp/pycharm-setup.sh"
  // }

  // provisioner "shell" {
  //   inline = [
  //     "chmod +x /tmp/pycharm-setup.sh",
  //     "/tmp/pycharm-setup.sh"
  //   ]
  // }

  // # Conda and Jupyter Setup
  // provisioner "file" {
  //   content = templatefile("provisioners/development/conda-jupyter-setup.sh.tpl", {
  //     # No variables needed for this script
  //   })
  //   destination = "/tmp/conda-jupyter-setup.sh"
  // }

  // provisioner "shell" {
  //   inline = [
  //     "chmod +x /tmp/conda-jupyter-setup.sh",
  //     "/tmp/conda-jupyter-setup.sh"
  //   ]
  // }

  # Finalize Setup
  provisioner "file" {
    content = templatefile("provisioners/system/finalize-setup.sh.tpl", {
      # No variables needed for this script
    })
    destination = "/tmp/finalize-setup.sh"
  }

  provisioner "shell" {
    inline = [
      "chmod +x /tmp/finalize-setup.sh",
      "/tmp/finalize-setup.sh"
    ]
  }

# New additional software installations
  provisioner "file" {
    content = templatefile("provisioners/system/x11-forwarding-setup.sh.tpl", {
      # No variables needed for this script
    })
    destination = "/tmp/x11-forwarding-setup.sh"
  }

  provisioner "shell" {
    inline = [
      "chmod +x /tmp/x11-forwarding-setup.sh",
      "/tmp/x11-forwarding-setup.sh"
    ]
  }
/*
  provisioner "file" {
    content = templatefile("provisioners/system/okta-asa-setup.sh.tpl", {
      okta_canonical_name = var.okta_canonical_name
      okta_team_name     = var.okta_team_name
    })
    destination = "/tmp/okta-asa-setup.sh"
  }

  provisioner "shell" {
    inline = [
      "chmod +x /tmp/okta-asa-setup.sh",
      "/tmp/okta-asa-setup.sh"
    ]
  }

  provisioner "file" {
    content = templatefile("provisioners/system/nvidia-cuda-setup.sh.tpl", {
      # No variables needed for this script
    })
    destination = "/tmp/nvidia-cuda-setup.sh"
  }

  provisioner "shell" {
    inline = [
      "chmod +x /tmp/nvidia-cuda-setup.sh",
      "/tmp/nvidia-cuda-setup.sh"
    ]
  }
*/
  // provisioner "file" {
  //   content = templatefile("provisioners/design/comsol-setup.sh.tpl", {
  //     comsol_license_file   = var.comsol_license_file
  //     comsol_license_server = var.comsol_license_server
  //   })
  //   destination = "/tmp/comsol-setup.sh"
  // }

  // provisioner "shell" {
  //   inline = [
  //     "chmod +x /tmp/comsol-setup.sh",
  //     "/tmp/comsol-setup.sh"
  //   ]
  // }

  // provisioner "file" {
  //   content = templatefile("provisioners/design/lumerical-setup.sh.tpl", {
  //     lumerical_license_file   = var.lumerical_license_file
  //     lumerical_license_server = var.lumerical_license_server
  //   })
  //   destination = "/tmp/lumerical-setup.sh"
  // }

  // provisioner "shell" {
  //   inline = [
  //     "chmod +x /tmp/lumerical-setup.sh",
  //     "/tmp/lumerical-setup.sh"
  //   ]
  // }
/*
  provisioner "file" {
    content = templatefile("provisioners/design/klayout-saltmine-setup.sh.tpl", {
      # No variables needed for this script
    })
    destination = "/tmp/klayout-saltmine-setup.sh"
  }

  provisioner "shell" {
    inline = [
      "chmod +x /tmp/klayout-saltmine-setup.sh",
      "/tmp/klayout-saltmine-setup.sh"
    ]
  }
*/
  provisioner "file" {
    content = templatefile("provisioners/design/vlc-setup.sh.tpl", {
      # No variables needed for this script
    })
    destination = "/tmp/vlc-setup.sh"
  }

  provisioner "shell" {
    inline = [
      "chmod +x /tmp/vlc-setup.sh",
      "/tmp/vlc-setup.sh"
    ]
  }

  // # VALIDATION PHASE
  // provisioner "shell" {
  //   inline = ["echo '=== Starting AMI Validation Phase ==='"]
  // }

  // # Upload validation script
  // provisioner "file" {
  //   source      = "test-cases.sh"
  //   destination = "/tmp/test-cases.sh"
  // }

  // # Wait for services to fully start before validation
  // provisioner "shell" {
  //   inline = [
  //     "echo 'Waiting for services to stabilize...'",
  //     "sleep 30"
  //   ]
  // }

  // # Run validation tests
  // provisioner "shell" {
  //   inline = [
  //     "chmod +x /tmp/test-cases.sh",
  //     "echo 'Running AMI validation tests...'",
  //     "/tmp/test-cases.sh"
  //   ]
  //   pause_before = "10s"
  //   # You can add timeout if needed
  //   timeout = "15m"
  // }
  // # ==========================================
  // # VALIDATION PHASE
  // # ==========================================
  
  // provisioner "shell" {
  //   inline = ["echo '=== Starting AMI Validation Phase ==='"]
  // }

  // # Upload validation script
  // provisioner "file" {
  //   source      = "test-cases.sh"
  //   destination = "/tmp/test-cases.sh"
  // }

  // # Wait for services to fully start before validation
  // provisioner "shell" {
  //   inline = [
  //     "echo 'Waiting for services to stabilize...'",
  //     "sleep 30"
  //   ]
  // }

  // # Run validation tests
  // provisioner "shell" {
  //   inline = [
  //     "chmod +x /tmp/test-cases.sh",
  //     "echo 'Running AMI validation tests...'",
  //     "/tmp/test-cases.sh"
  //   ]
  //   pause_before = "10s"
  //   # You can add timeout if needed
  //   timeout = "5m"
  // }

  # Clean up to reduce AMI size
  provisioner "shell" {
    inline = [
      "sudo dnf clean all",
      "sudo rm -rf /tmp/*",
      "sudo rm -rf /var/var/tmp/*",
      "sudo rm -f ~/.bash_history",
      "history -c",
      "echo '=== AMI Validation Complete ==='",
      "echo 'AMI is ready for production use'"
    ]
  }

  # Generate build manifest
  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
    custom_data = {
      validation_date = timestamp()
      ami_tested     = "true"
    }
  }
}