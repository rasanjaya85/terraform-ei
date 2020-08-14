#----------------------------------------------------------------------------
#  Copyright (c) 2018 WSO2, Inc. http://www.wso2.org
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#----------------------------------------------------------------------------

variable "ei_cookie_name" {
  default = "X-Oracle-OCI-ei"
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

/* Network */
resource "oci_core_vcn" "vcn" {
  cidr_block     = "10.1.0.0/16"
  compartment_id = var.compartment_ocid
  display_name   = "vcn"
  dns_label      = "vcn"
}

resource "oci_core_subnet" "public_subnet" {
  availability_domain = lookup(data.oci_identity_availability_domains.ads.availability_domains[var.ad - 1], "name")
  cidr_block          = "10.1.20.0/24"
  display_name        = "public-subnet"
  dns_label           = "publicsubnet"
  security_list_ids   = [oci_core_security_list.security_list.id]
  compartment_id      = var.compartment_ocid
  vcn_id              = oci_core_vcn.vcn.id
  route_table_id      = oci_core_route_table.route_table.id
  dhcp_options_id     = oci_core_vcn.vcn.default_dhcp_options_id

  provisioner "local-exec" {
    command = "sleep 5"
  }
}

resource "oci_core_internet_gateway" "internet_gateway" {
  compartment_id = var.compartment_ocid
  display_name   = "internet_gateway"
  vcn_id         = oci_core_vcn.vcn.id
}

resource "oci_core_route_table" "route_table" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "route-table"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.internet_gateway.id
  }
}

resource "oci_core_security_list" "security_list" {
  display_name   = "public"
  compartment_id = oci_core_vcn.vcn.compartment_id
  vcn_id         = oci_core_vcn.vcn.id

  // allow outbound tcp traffic on all ports
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "6"
  }

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "1"
    stateless   = true
  }

  // allow inbound traffic from a specific port
  ingress_security_rules {
    protocol  = "6" // tcp
    source    = "0.0.0.0/0"
    stateless = true
  }

  // allow inbound icmp traffic of a specific type
  ingress_security_rules {
    protocol  = 1
    source    = "0.0.0.0/0"
    stateless = true
  }
}

resource "oci_database_db_system" "oracle_dbsystem" {
  availability_domain = lookup(data.oci_identity_availability_domains.ads.availability_domains[var.ad - 1], "name")
  compartment_id      = var.compartment_ocid
  cpu_core_count      = var.cpu_core_count
  database_edition    = var.db_edition

  db_home {
    database {
      admin_password = var.db_admin_password
      db_name        = "intsvrdb"
    }

    db_version   = var.db_version
    display_name = "EIOracleDB"
  }

  shape           = var.db_system_shape
  subnet_id       = oci_core_subnet.public_subnet.id
  ssh_public_keys = [file(var.ssh_public_key)]
  display_name    = var.db_system_display_name

  hostname                = var.hostname
  data_storage_size_in_gb = var.data_storage_size_in_gb
  node_count              = var.node_count
  freeform_tags = {
    "name" = "EI"
  }
}

/* Instances */
resource "oci_core_instance" "ei_instance1" {
  depends_on          = ["oci_database_db_system.oracle_dbsystem"]
  availability_domain = lookup(data.oci_identity_availability_domains.ads.availability_domains[var.ad - 1], "name")
  compartment_id      = var.compartment_ocid
  display_name        = "ei-01"
  shape               = var.instance_shape

  source_details {
    source_type = "image"
    source_id   = var.instance_image_ocid[var.region]
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.public_subnet.id
    hostname_label   = "ei-01"
    assign_public_ip = true
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key)
    user_data           = base64encode(data.template_cloudinit_config.database_template_script.rendered)
  }

}

resource "oci_core_instance" "ei_instance2" {
  depends_on          = ["oci_core_instance.ei_instance1"]
  availability_domain = lookup(data.oci_identity_availability_domains.ads.availability_domains[var.ad - 1], "name")
  compartment_id      = var.compartment_ocid
  display_name        = "ei-02"
  shape               = var.instance_shape

  source_details {
    source_type = "image"
    source_id   = var.instance_image_ocid[var.region]
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.public_subnet.id
    hostname_label   = "ei-02"
    assign_public_ip = true
  }

  metadata = {
    //    ssh_authorized_keys = "${var.ssh_public_key}"
    ssh_authorized_keys = file(var.ssh_public_key)
    user_data           = base64encode(data.template_file.compute_template_script.rendered)
  }

}

/* Load Balancer */
resource "oci_load_balancer" "lb_ei" {
  shape          = "100Mbps"
  compartment_id = var.compartment_ocid
  subnet_ids     = [oci_core_subnet.public_subnet.id]
  display_name   = "ei-loadbalancer"
}

resource "oci_load_balancer_hostname" "ei_hostname1" {
  #Required
  hostname         = "ei1.wso2test.com"
  load_balancer_id = oci_load_balancer.lb_ei.id
  name             = "ei1"
}

resource "oci_load_balancer_hostname" "ei_hostname2" {
  #Required
  hostname         = "ei2.wso2test.com"
  load_balancer_id = oci_load_balancer.lb_ei.id
  name             = "ei2"
}


resource "oci_load_balancer_listener" "https_listener_9443" {
  load_balancer_id         = oci_load_balancer.lb_ei.id
  name                     = "https-9443"
  default_backend_set_name = oci_load_balancer_backend_set.backend_set_9443.name
  hostname_names           = [oci_load_balancer_hostname.ei_hostname1.name, oci_load_balancer_hostname.ei_hostname2.name]
  port                     = 9443
  protocol                 = "HTTP"

  ssl_configuration {
    certificate_name        = oci_load_balancer_certificate.lb_certificate.certificate_name
    verify_peer_certificate = false
  }
}

resource "oci_load_balancer_listener" "https_listener_8243" {
  load_balancer_id         = oci_load_balancer.lb_ei.id
  name                     = "https-8243"
  default_backend_set_name = oci_load_balancer_backend_set.backend_set_8243.name
  hostname_names           = [oci_load_balancer_hostname.ei_hostname1.name, oci_load_balancer_hostname.ei_hostname2.name]
  port                     = 8243
  protocol                 = "HTTP"

  ssl_configuration {
    certificate_name        = oci_load_balancer_certificate.lb_certificate.certificate_name
    verify_peer_certificate = false
  }
}

resource "oci_load_balancer_certificate" "lb_certificate" {
  certificate_name   = "certificate1"
  load_balancer_id   = oci_load_balancer.lb_ei.id
  ca_certificate     = local.ssl_ca_key
  private_key        = local.ssl_private_key
  public_certificate = local.ssl_public_key

  lifecycle {
    create_before_destroy = true
  }
}

resource "oci_load_balancer_backend_set" "backend_set_9443" {
  name             = "ei-backendset-9443"
  load_balancer_id = oci_load_balancer.lb_ei.id
  policy           = "ROUND_ROBIN"


  health_checker {
    port                = "9443"
    protocol            = "HTTP"
    response_body_regex = ".*"
    url_path            = "/carbon/admin/login.jsp"
    return_code         = 200
    retries             = 3
    interval_ms         = 5000
  }

  session_persistence_configuration {
    cookie_name = var.ei_cookie_name
  }

  ssl_configuration {
    certificate_name = oci_load_balancer_certificate.lb_certificate.certificate_name
  }
}

resource "oci_load_balancer_backend" "lb_backend1_9443" {
  load_balancer_id = oci_load_balancer.lb_ei.id
  backendset_name  = oci_load_balancer_backend_set.backend_set_9443.name
  ip_address       = oci_core_instance.ei_instance1.private_ip
  port             = 9443
  backup           = false
  drain            = false
  offline          = false
  weight           = 1
}

resource "oci_load_balancer_backend" "lb_backend2_9443" {
  load_balancer_id = oci_load_balancer.lb_ei.id
  backendset_name  = oci_load_balancer_backend_set.backend_set_9443.name
  ip_address       = oci_core_instance.ei_instance2.private_ip
  port             = 9443
  backup           = false
  drain            = false
  offline          = false
  weight           = 1
}

resource "oci_load_balancer_backend_set" "backend_set_8243" {
  name             = "ei-backendset-8243"
  load_balancer_id = oci_load_balancer.lb_ei.id
  policy           = "ROUND_ROBIN"


  health_checker {
    port                = "8243"
    protocol            = "HTTP"
    response_body_regex = ".*"
    url_path            = "/services/Version"
    return_code         = 200
    retries             = 3
    interval_ms         = 5000
  }
  ssl_configuration {
    certificate_name = oci_load_balancer_certificate.lb_certificate.certificate_name
  }
}

resource "oci_load_balancer_backend" "lb_backend1_8243" {
  load_balancer_id = oci_load_balancer.lb_ei.id
  backendset_name  = oci_load_balancer_backend_set.backend_set_8243.name
  ip_address       = oci_core_instance.ei_instance1.private_ip
  port             = 8243
  backup           = false
  drain            = false
  offline          = false
  weight           = 1
}

resource "oci_load_balancer_backend" "lb_backend2_8243" {
  load_balancer_id = oci_load_balancer.lb_ei.id
  backendset_name  = oci_load_balancer_backend_set.backend_set_8243.name
  ip_address       = oci_core_instance.ei_instance2.private_ip
  port             = 8243
  backup           = false
  drain            = false
  offline          = false
  weight           = 1
}