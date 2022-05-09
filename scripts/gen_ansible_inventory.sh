#/bin/bash
​
set +ex
​
mkdir -p config/${ENVIRONMENT}/.cache/rke2-ansible/inventory/files/manifest/
mkdir -p config/${ENVIRONMENT}/.cache/rke2-ansible/inventory/group_vars/
​
cat > config/${ENVIRONMENT}/.cache/rke2-ansible/inventory/files/registries.yaml <<EOF
---
mirrors:
  docker.io:
    endpoint:
      - "https://${HARBOR_INGRESS_DNS}"
      - "https://registry-1.docker.io"
configs:
  "https://${HARBOR_INGRESS_DNS}":
    tls:
      insecure_skip_verify: true
EOF
​
cat > config/${ENVIRONMENT}/.cache/rke2-ansible/inventory/group_vars/rke2_servers.yaml <<EOF
---
rke2_channel: stable
​
rke2_config: 
  disable: rke2-ingress-nginx
  tls-san:
    - ${RKE2_API_VIP}
    - ${RKE2_API_DNS}
​
registry_config_file_path: "{{ playbook_dir }}/inventory/{{ lookup('env', 'ENVIRONMENT') }}/files/registries.yaml"
​
manifest_config_file_path: "{{ playbook_dir }}/inventory/{{ lookup('env', 'ENVIRONMENT') }}/files/manifest/"
EOF
​
cat > config/${ENVIRONMENT}/.cache/rke2-ansible/inventory/group_vars/rke2_agents.yaml <<EOF
---
rke2_channel: v1.21
EOF
​
## Build hosts.ini to include IP, Node Names and Ansible Vars.
​
cat >> config/${ENVIRONMENT}/.cache/rke2-ansible/inventory/hosts.ini <<EOF
[rke2_servers]
EOF
​
VM_LIST=$(cat config/${ENVIRONMENT}/.cache/vm-terraform.tfstate | jq .outputs.vms.value[].ip_address)
INDEX=0
for i in ${VM_LIST}; do
  export HOSTNAME=$(cat config/${ENVIRONMENT}/.cache/vm-terraform.tfstate | jq .outputs.vms.value[${INDEX}].name -r)
  export IPV4_ADDR=$(cat config/${ENVIRONMENT}/.cache/vm-terraform.tfstate | jq .outputs.vms.value[${INDEX}].ip_address -r)
  echo "${IPV4_ADDR} node_name='${HOSTNAME}' ansible_user=${SSH_USERNAME}" >> config/${ENVIRONMENT}/.cache/rke2-ansible/inventory/hosts.ini
  let INDEX=${INDEX}+1
done
​
cat <<EOF >> config/${ENVIRONMENT}/.cache/rke2-ansible/inventory/hosts.ini
​
[rke2_agents]
​
[rke2_cluster:children]
rke2_servers
rke2_agents
​
[all:vars]
ansible_ssh_common_args='-o UserKnownHostsFile=/dev/null'
EOF
​
## Overriding Ansible Repo Yaml Files
​
mkdir -p config/${ENVIRONMENT}/.cache/rke2-ansible/roles/rke2_common/vars/
cat > config/${ENVIRONMENT}/.cache/rke2-ansible/roles/rke2_common/vars/main.yml <<EOF
---
# Possible RKE2 Channels
channels:
  - stable
  - latest
  - v1.21
  - v1.20
  - v1.19
  - v1.18
​
installed: false
EOF