# setup creates a local cluster using kind. It also installs istio
# and sets it up using strict security settings (strict mtls, deny by default)
.PHONY: setup
setup:
	cloud-provider-kind &> /dev/null & 
	kind create cluster --config cluster/cluster.yaml
	bash cluster/charts.sh
	kubectl create -f cluster/istio_defaults.yaml

# teardown removes the existing cluster and any background processes used to run it	
.PHONY: teardown 
teardown:
	kind delete cluster --name istio-cluster
	kill $$(ps -aux | grep cloud-provider-kind | grep -v "grep" | grep -v "bash" | tr -s ' ' | cut -d ' ' -f 2)

# cassandra installs the k8ssandra helm chart and it's dependencies,
# creates a 3-replica cassandra cluster, and creates a cql client.
# Once created 
.PHONY: cassandra
cassandra:
	helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set installCRDs=true
	kubectl create -f k8ssandra/namespaces.yaml
	kubectl create -f k8ssandra/operator.yaml
	helm install k8ssandra-operator k8ssandra/k8ssandra-operator -n k8ssandra-operator --create-namespace -f k8ssandra/values.yaml
	echo "waiting for 30 seconds for the webhook to come up"
	sleep 30
	kubectl create -f k8ssandra/cluster.yaml
	kubectl create -f k8ssandra/client.yaml
	echo "resources created, wait for 5 minutes for the cluster to come up"

# postgres installs the cnpg helm chart, creates a 3 replica postgres
# cluster, and creates a psql client. See cnpg/readme.md for more 
# details on using the client post provisioning. 
.PHONY: postgres
postgres:
	kubectl create -f cnpg/namespaces.yaml
	kubectl create -f cnpg/operator.yaml
	helm install cnpg cnpg/cloudnative-pg --namespace cnpg-system -f cnpg/values.yaml
	echo "waiting for 30 seconds for the webhook to come up"
	sleep 30
	kubectl create -f cnpg/cluster.yaml
	kubectl create -f cnpg/client.yaml
	echo "resources created, wait for 3 minutes for the cluster to come up"
