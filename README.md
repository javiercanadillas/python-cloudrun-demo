Edit `config_vars` with your preferred values. Then run `setup_demo.sh` to prepare the environment. The script will:
- Prepare environment variables and enable necessary APIs.
- Create a GKE Cluster with Cloud Run enabled
- Set up gcloud environment to use the GKE cluster with Cloud Run
- Set up a Cloud Run specific namespace

Get external IP for the Istio Ingress
export GATEWAY_IP=kubectl get svc istio-ingress --namespace gke-system --output jsonpath={.status.loadBalancer.ingress[0].ip}

kubectl patch configmap config-domain --namespace knative-serving --patch \
'{"data": {"example.com": null, '$EXTERNAL-IP'.xip.io": ""}}'