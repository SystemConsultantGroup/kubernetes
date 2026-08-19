# GitHub team SystemConsultantGroup:active manages application secret values.
path "kv/data/*" {
  capabilities = ["create", "read", "update", "patch", "delete"]
}

path "kv/metadata/*" {
  capabilities = ["create", "read", "update", "patch", "delete", "list"]
}

path "kv/delete/*" {
  capabilities = ["update"]
}

path "kv/undelete/*" {
  capabilities = ["update"]
}

path "kv/destroy/*" {
  capabilities = ["update"]
}

path "kv/config" {
  capabilities = ["read"]
}

path "sys/internal/ui/mounts" {
  capabilities = ["read"]
}

path "sys/internal/ui/mounts/*" {
  capabilities = ["read"]
}

path "sys/internal/ui/resultant-acl" {
  capabilities = ["read"]
}
