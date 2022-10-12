.PHONY: clean create log service show sql

create:
	@echo -n "+ "
	./ex-storage-pv-local.sh create
	@echo -n "+ "
	kubectl apply -f ex-storage-pv-local-pod.yaml

clean:
	@echo -n "+ "
	-kubectl delete -f ex-storage-pv-local-pod.yaml
	@echo -n "+ "
	-./ex-storage-pv-local.sh delete

show:
	@echo -n "+ "
	-./ex-storage-pv-local.sh show
	@echo -n "+ "
	-kubectl get pvc
	@echo -n "+ "
	-kubectl describe pv ex-storage-pv
	@echo -n "+ "
	-kubectl describe pvc local-claim
	@echo -n "+ "
	-kubectl describe pod ex-storage-pv-local-pod
	@echo -n "+ "
	-kubectl logs ex-storage-pv-local-pod
