{{- define "application.bunkerwebIngress" -}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ .name }}
  namespace: {{ .namespace }}
  annotations:
    bunkerweb.io/REVERSE_PROXY_HEADERS_1: "X-Forwarded-For $remote_addr"
    bunkerweb.io/REVERSE_PROXY_WS_1: "yes"
    {{- if .external }}
    bunkerweb.io/REVERSE_PROXY_HOST_1: {{ printf "http://%s.%s.svc.cluster.local" .backend .namespace | quote }}
    bunkerweb.io/AUTO_REDIRECT_HTTP_TO_HTTPS: "no"
    {{- else }}
    bunkerweb.io/REVERSE_PROXY_SSL_SNI: "yes"
    bunkerweb.io/REVERSE_PROXY_SSL_SNI_NAME: "$host"
    bunkerweb.io/REVERSE_PROXY_SSL_VERIFY: "yes"
    bunkerweb.io/REVERSE_PROXY_SSL_TRUSTED_CERTIFICATE: /etc/ssl/certs/ca-certificates.crt
    {{- end }}
    bunkerweb.io/SECURITY_MODE: {{ ternary "block" "detect" (.protect | default false) }}
spec:
  ingressClassName: bunkerweb
  {{- if not .external }}
  tls:
    - secretName: {{ .tlsSecret }}
      hosts:
        - {{ .hostname | quote }}
  {{- end }}
  rules:
    - host: {{ .hostname | quote }}
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: {{ .backend }}
                port:
                  number: {{ ternary 80 443 (.external | default false) }}
{{- end -}}
