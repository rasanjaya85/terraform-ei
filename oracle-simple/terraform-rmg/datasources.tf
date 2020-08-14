data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

data "template_file" "database_tempalte_script" {
  template = file("${path.module}/scripts/database.sh.tpl")

  vars = {
    db_admin_password     = var.db_admin_password
    db_connection_strings = oci_database_db_system.oracle_dbsystem.db_home[0].database[0].connection_strings[0].all_connection_strings.cdbDefault
  }

}

data "template_file" "compute_template_script" {
  template = file("${path.module}/cloudinit/compute.tpl")
  vars = {
    db_connection_strings  = oci_database_db_system.oracle_dbsystem.db_home[0].database[0].connection_strings[0].all_connection_strings.cdbDefault
    shared_server_hostname = oci_file_storage_mount_target.artifact_mount_target.hostname_label
  }
}

data "template_cloudinit_config" "database_template_script" {
  gzip          = false
  base64_encode = false
  part {
    filename     = "compute.cfg"
    content_type = "text/cloud-config"
    content      = data.template_file.compute_template_script.rendered
  }
}
