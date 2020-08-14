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

variable "tenancy_ocid" {
  //  default = "ocid1.tenancy.oc1..aaaaaaaaevjobrm7caz5ht5pxe54lugtjqnmwdddptx2fgfjnwypbj7xeatq"
}

locals {
  ssl_private_key = "${file("ssl-keys/private-key.pem")}"
  ssl_public_key  = "${file("ssl-keys/public.pem")}"
  ssl_ca_key      = "${file("ssl-keys/public.pem")}"
}

variable "compartment_ocid" {
  //  default = "ocid1.compartment.oc1..aaaaaaaasl53aby2rdof7sx6yusxkggechxmikc5vt3zxvr4ulkmf2bd6x6a"
}

variable "region" {
  //  default = "ap-tokyo-1"
}

variable "user_ocid" {
  //  default = "ocid1.user.oc1..aaaaaaaanipsyprvr2i6qaivamjur64n32akubcpulkdmksw43wwnsl2xz3q"
}

variable "fingerprint" {
  //  default = "b1:9d:55:d9:5f:3d:4f:05:e9:12:55:2b:65:fc:19:94"
}

variable "private_key_path" {
  default = "~/.oci/oci_api_key.pem"
}

variable "ad" {
  default = "1"
}

variable "instance_image_ocid" {
  type = "map"

  default = {
    # See https://docs.us-phoenix-1.oraclecloud.com/images/
    # Oracle-provided image "Oracle-Linux-7.5-2018.10.16-0"
    //    ap-tokyo-1 = "ocid1.image.oc1.ap-tokyo-1.aaaaaaaai3lkdjjrgnwx433ikf5zxw53v2lxiwmbdlckac6fltcgh3szwd6q"
    ap-tokyo-1 = "ocid1.image.oc1.ap-tokyo-1.aaaaaaaaqvfti4np4vytiveg3prdb45nizmhtgrcos7kezmgack66hzmydva"
  }
}

variable "instance_shape" {
  default = "VM.Standard2.1"
}

variable "availability_domain" {
  default = 1
}

variable "db_edition" {
  default = "STANDARD_EDITION"
}

variable "db_admin_password" {
  default = "BEstrO0ng_#12"
}

variable "db_version" {
  default = "12.1.0.2"
}

variable "db_system_shape" {
  default = "VM.Standard2.2"
}

variable "db_system_display_name" {
  default = "ApimDBsystem"
}

variable "hostname" {
  default = "apimoracledb"
}

variable "node_count" {
  default = "1"
}

variable "cpu_core_count" {
  default = "2"
}

variable "data_storage_size_in_gb" {
  default = "256"
}

variable "ssh_public_key" {}
//variable "ssh_public_key_path" {}

//locals {
//  ssh_public_key = "${file("ssh-keys/oracle-ssh.pub")}"
//}
