output "lb_public_ip" {
  value = [oci_load_balancer.lb_ei.ip_address_details]
}

output "instance1_public_ip" {
  value = [oci_core_instance.ei_instance1.public_ip]
}

output "instance2_public_ip" {
  value = [oci_core_instance.ei_instance2.public_ip]
}

output "nfs_private_ip" {
  value = oci_file_storage_mount_target.artifact_mount_target.hostname_label
}

output "db_connection_strings" {
  value = oci_database_db_system.oracle_dbsystem.db_home[0].database[0].connection_strings[0].all_connection_strings.cdbDefault
}
