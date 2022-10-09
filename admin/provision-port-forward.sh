NODE_PORT=$1

APIKEY='XXKqu0-RxMudn1BE8j_UY4k9NSArZqV24IHYFonv2H7L'

echo "Provision port forwarding for ${NODE_PORT}"

# Get Access Token
IAM_ACCESS_TOKEN=$(curl -X POST -s 'https://iam.cloud.ibm.com/identity/token' -H 'Content-Type: application/x-www-form-urlencoded' -d "grant_type=urn:ibm:params:oauth:grant-type:apikey&apikey=${APIKEY}" | jq -r '.access_token')

# Create Backendpool
BACKENDPOOL_RESPONSE=$(
curl -s -X POST \
  "https://eu-de.iaas.cloud.ibm.com/v1/load_balancers/r010-4cdc0c5a-186b-40b3-90f0-259cc9571b70/pools?version=2022-09-15&generation=2" \
  -H "Authorization: Bearer $IAM_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -H "accept: application/json" \
  --data-binary @- << EOF
{
  "name": "tcp-${NODE_PORT}-32038",
  "protocol": "tcp",
  "algorithm": "round_robin",
  "health_monitor": {
    "type": "tcp",
    "delay": 5,
    "max_retries": 2,
    "timeout": 2,
    "url_path": "/",
    "port": 32038
  },
  "proxy_protocol": "disabled",
  "members": [
    {
      "target": {
        "address": "10.243.0.7"
      },
      "port": ${NODE_PORT}
    },
    {
      "target": {
        "address": "10.243.64.7"
      },
      "port": ${NODE_PORT}
    }
  ]
}
EOF
);
BACKENDPOOL_ID=$(echo $BACKENDPOOL_RESPONSE | jq -r '.id');

echo "Created Backendpool ${BACKENDPOOL_ID}";

# Create a load balancer listener
FRONTEND_RESPONSE=$(
curl -s -X POST \
  "https://eu-de.iaas.cloud.ibm.com/v1/load_balancers/r010-4cdc0c5a-186b-40b3-90f0-259cc9571b70/listeners?version=2022-09-15&generation=2" \
  -H "Authorization: Bearer $IAM_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -H "accept: application/json" \
  --data-binary @- << EOF
{
  "protocol": "tcp",
  "port": ${NODE_PORT},
  "connection_limit": 15000,
  "accept_proxy_protocol": false,
  "default_pool": {
    "id": "${BACKENDPOOL_ID}"
  }
}
EOF
);
FRONTEND_ID=$(echo $FRONTEND_RESPONSE | jq -r '.id');

echo "Created Frontend ${FRONTEND_ID}";

echo "Test with:"
echo "wscat -c ws://hslu-openshift-cluster-e756cf5e9c60afaa4e8e24ae78ebfb82-0000.eu-de.containers.appdomain.cloud:${NODE_PORT}"
