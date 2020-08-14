resource "oci_file_storage_mount_target" "artifact_mount_target" {
  availability_domain = lookup(data.oci_identity_availability_domains.ads.availability_domains[var.ad - 1], "name")
  compartment_id      = var.compartment_ocid
  subnet_id           = oci_core_subnet.public_subnet.id
  display_name        = "artifact-mount-target"
  hostname_label      = "ei-nfs-server"
}

resource "oci_file_storage_export_set" "artifact_export_set" {
  mount_target_id = oci_file_storage_mount_target.artifact_mount_target.id
  display_name    = "artifact-export-set"
}

resource "oci_file_storage_file_system" "artifact_file_system" {
  availability_domain = lookup(data.oci_identity_availability_domains.ads.availability_domains[var.ad - 1], "name")
  compartment_id      = var.compartment_ocid
  display_name        = "artifact-filesystem"
}

resource "oci_file_storage_export" "deployment_export" {
  export_set_id  = oci_file_storage_mount_target.artifact_mount_target.export_set_id
  file_system_id = oci_file_storage_file_system.artifact_file_system.id
  path           = "/sharedfs"
}
