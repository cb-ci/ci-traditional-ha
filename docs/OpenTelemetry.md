
# Access to Jaeger (Traces)

Access to Jeager works currently just from Webtop, not from docker host!

* open webtop

```
open http://localhost:3000
```
* open Chromium
* Login to OC
* Got to Controller test Job
* Run the job
* Click on the Jaeger link in the built overview


# Test connection 
```
curl -v http://otel-collector:4318/v1/traces \
-H 'Content-Type: application/json' \
--data '{}'
```


```
# macOS: get current time in nanoseconds
NS=$(python3 - <<'PY'
import time; print(int(time.time()*1e9))
PY)

cat > traces.json <<EOF
{
  "resourceSpans": [{
    "resource": {
      "attributes": [
        {"key": "service.name", "value": {"stringValue": "curl-test"}},
        {"key": "telemetry.sdk.language", "value": {"stringValue": "manual"}}
      ]
    },
    "scopeSpans": [{
      "scope": {"name": "curl"},
      "spans": [{
        "traceId": "00000000000000000000000000000001",
        "spanId":  "0000000000000001",
        "name": "curl-span",
        "kind": "SPAN_KIND_INTERNAL",
        "startTimeUnixNano": "$NS",
        "endTimeUnixNano":   "$NS"
      }]
    }]
  }]
}
EOF

curl -v http://otel-collector:4318/v1/traces \
  -H 'Content-Type: application/json' \
  --data @traces.json


```
