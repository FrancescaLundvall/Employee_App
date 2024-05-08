{{- with secret "database/creds/admin-role" }}
username: "{{ .Data.username }}"
password: "{{ .Data.password }}"
database: "HashiCorpDemo"
{{- end }}

