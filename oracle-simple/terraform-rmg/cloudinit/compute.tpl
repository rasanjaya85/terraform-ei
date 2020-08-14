#cloud-config

mounts:
 - [ "${shared_server_hostname}:/sharedfs", /mnt/sharedfs, "nfs", "rsize=8192,wsize=8192,timeo=14,intr", "0", "0" ]

runcmd:
 - sed -i 's|CONNECTION_STRING|${db_connection_strings}|g' /home/opc/ansible-ei/dev/group_vars/all.yml
 - cd /home/opc/ansible-ei &&  ansible-playbook -i dev/inventory site.yml