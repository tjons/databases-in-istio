helm install istio-base istio/base -n istio-system --set defaultRevision=default --create-namespace
helm install istiod istio/istiod -n istio-system --wait
helm install isitio-ingress istio/gateway -n istio-ingress --wait --create-namespace
