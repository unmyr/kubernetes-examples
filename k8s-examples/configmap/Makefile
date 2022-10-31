NAMESPACE=ex-job-with-cfm
JOB_NAME=ex-job-with-cfm
apply:
	@echo -n "+ "
	-time kubectl apply -f job_with_configmap.yaml

show:
	@echo -n "+ "
	kubectl get -n $(NAMESPACE) configmap,job,pod
	@kubectl get pods --selector=job-name=$(JOB_NAME) --output=jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' -n $(NAMESPACE) | while read POD_NAME; do (set -x; kubectl logs -n $(NAMESPACE) $${POD_NAME} | tail; kubectl exec -n $(NAMESPACE) $${POD_NAME} -- cat /fruits-volume/fruits.txt); done

del_cfg:
	@echo -n "+ "
	-kubectl delete configmap -n $(NAMESPACE) fruits

clean:
	@echo -n "+ "
	-time kubectl delete -f job_with_configmap.yaml

