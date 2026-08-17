if (($# > 1)) || (($# == 1)) && [[ $1 != --check ]]; then
  echo "Usage: k generate application-schemas [--check]" >&2
  return 2
fi

check=0
[[ ${1:-} != --check ]] || check=1

generate_application_schemas() (
  set -euo pipefail

  local tmp kubernetes_url gateway_url
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT

  kubernetes_url="https://raw.githubusercontent.com/kubernetes/kubernetes/v$KUBERNETES_VERSION/api/openapi-spec/swagger.json"
  gateway_url="https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v$GATEWAY_API_VERSION/config/crd/standard/gateway.networking.k8s.io_httproutes.yaml"

  curl -fsSL "$kubernetes_url" -o "$tmp/kubernetes.json"
  curl -fsSL "$gateway_url" -o "$tmp/httproute.yaml"

  jq --argjson roots '[
            "io.k8s.api.core.v1.EnvVar",
            "io.k8s.api.core.v1.EnvFromSource",
            "io.k8s.api.core.v1.ResourceRequirements",
            "io.k8s.api.core.v1.Probe"
        ]' '
        def refs:
            [
                .. | objects | .["$ref"]?
                | select(type == "string" and startswith("#/definitions/"))
                | ltrimstr("#/definitions/")
            ];
        def closure($definitions; $pending; $selected):
            if ($pending | length) == 0 then
                $selected
            else
                $pending[0] as $name
                | if ($selected | index($name)) != null then
                    closure($definitions; $pending[1:]; $selected)
                  elif $definitions[$name] == null then
                    error("missing Kubernetes definition: " + $name)
                  else
                    closure(
                        $definitions;
                        $pending[1:] + ($definitions[$name] | refs);
                        $selected + [$name]
                    )
                  end
            end;
        def normalize:
            walk(
                if type == "object" then
                    del(.description)
                    | if .type == "object"
                         and has("properties")
                         and (has("additionalProperties") | not)
                      then .additionalProperties = false
                      else .
                      end
                else .
                end
            );
        . as $document
        | closure(.definitions; $roots; []) as $selected
        | reduce ($selected | sort[]) as $name (
            {};
            .[$name] = ($document.definitions[$name] | normalize)
          )
        | .["io.k8s.apimachinery.pkg.util.intstr.IntOrString"] = {
            "$comment": "Kubernetes OpenAPI v2 models IntOrString as a string format; this expansion preserves its actual wire shape.",
            "oneOf": [
                {"type": "integer", "format": "int32"},
                {"type": "string"}
            ]
          }
    ' "$tmp/kubernetes.json" >"$tmp/kubernetes-definitions.json"

  yq -o=json '
        .spec.versions[]
        | select(.name == "v1")
        | .schema.openAPIV3Schema.properties.spec.properties.rules.items
    ' "$tmp/httproute.yaml" |
    jq '
            def normalize:
                walk(
                    if type == "object" then
                        del(.description)
                        | if .type == "object"
                             and has("properties")
                             and (has("additionalProperties") | not)
                          then .additionalProperties = false
                          else .
                          end
                    else .
                    end
                );
            normalize
            | if type != "object" or (has("properties") | not)
              then error("Gateway API CRD has no v1 HTTPRouteRule schema")
              else .
              end
        ' >"$tmp/httprouterule.json"

  jq -n \
    --arg version "$KUBERNETES_VERSION" \
    --arg source "$kubernetes_url" \
    --slurpfile definitions "$tmp/kubernetes-definitions.json" '
        {
            "$schema": "https://json-schema.org/draft/2020-12/schema",
            "title": ("Selected Kubernetes v" + $version + " API types"),
            "$comment": ("Generated from " + $source + ". Descriptions were removed, object schemas were made strict, and IntOrString was normalized."),
            "definitions": $definitions[0]
        }
    ' >"$tmp/kubernetes.schema.json"

  jq \
    --arg version "$GATEWAY_API_VERSION" \
    --arg source "$gateway_url" '
        {
            "$schema": "https://json-schema.org/draft/2020-12/schema",
            "title": ("Gateway API v" + $version + " HTTPRouteRule"),
            "$comment": ("Generated from " + $source + ". Descriptions were removed and object schemas were made strict.")
        } + .
    ' "$tmp/httprouterule.json" >"$tmp/httprouterule.schema.json"

  jq \
    --arg kubernetes "$KUBERNETES_VERSION" \
    --arg gateway "$GATEWAY_API_VERSION" \
    --slurpfile definitions "$tmp/kubernetes-definitions.json" \
    --slurpfile rule "$tmp/httprouterule.json" '
        def embedded_refs:
            walk(
                if type == "object"
                   and (.["$ref"]? | type) == "string"
                   and (.["$ref"] | startswith("#/definitions/"))
                then .["$ref"] |= sub("^#/definitions/"; "#/$defs/kubernetesDefinitions/")
                else .
                end
            );
        .["$comment"] = (
            "Generated with Kubernetes v" + $kubernetes
            + " and Gateway API v" + $gateway
            + "; edit values.schema.source.json instead."
        )
        | .["$defs"].kubernetesDefinitions = ($definitions[0] | embedded_refs)
        | .["$defs"].httpRouteRule = $rule[0]
    ' "$ROOT_DIR/argocd/charts/application/values.schema.source.json" \
    >"$tmp/values.schema.json"

  write_generated() {
    local source="$1" destination="$2"
    if [[ -f $destination ]] && cmp -s "$source" "$destination"; then
      return
    fi
    if ((check)); then
      echo "Stale generated schema: ${destination#"$ROOT_DIR/"}" >&2
      return 1
    fi
    mkdir -p "$(dirname "$destination")"
    cp "$source" "$destination"
    echo "Generated ${destination#"$ROOT_DIR/"}"
  }

  write_generated "$tmp/values.schema.json" "$ROOT_DIR/argocd/charts/application/values.schema.json"
)

generate_application_schemas
