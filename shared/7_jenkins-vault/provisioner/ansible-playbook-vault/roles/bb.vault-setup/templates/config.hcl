listener "tcp" {
  address = "{{ _vault_address_port }}"
  tls_disable = 1
}

# Use local filesystem as backend
#backend "file" {
#  path = "{{ _vault_file_backend_dir }}"
#}

# Use S3 as storage backend
storage "s3" {
  region = "us-east-2"
  bucket = "lh-shared-vault-storage"
}

max_lease_ttl = "{{ _vault_max_lease_ttl }}"
default_lease_ttl = "{{ _vault_default_lease_ttl }}"