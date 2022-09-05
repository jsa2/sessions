

https://kubernetes.io/docs/tasks/debug/debug-application/get-shell-running-container/

https://release-v0-11.docs.openservicemesh.io/docs/getting_started/quickstart/manual_demo/

```yaml
kind: Pod
apiVersion: v1
metadata:
  namespace: default
  name: cli23
  labels:
    app: cli23
spec:
  containers:
    - name: busybox
      image: k8s.gcr.io/e2e-test-images/busybox:1.29-1
      command:
        - "/bin/sleep"
        - "10000"
``` 

```sh
kubectl exec --stdin --tty shell-demo -- /bin/bash
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kali2
  labels:
    app: kali2
spec:
  containers:
  - name: kali
    image: kalilinux/kali-rolling
    command:
        - "/bin/sleep"
        - "10000"
  hostNetwork: true
  dnsPolicy: Default
``` 

```sh
kubectl apply -f kali.yaml 
kubectl exec --stdin --tty kali -n kali -- /bin/bash
```

# Once in KALI
```sh
apt update -y; apt install curl -y;
apt install netcat-traditional -y;
apt install wfuzz -y
apt install dnsutils -y;
apt install iputils-ping -y 

curl nginx2.ngi.svc.cluster.local:8888




nslookup nginx2.ngi.svc.cluster.local 10.0.0.10
```


# Expose NGI
//


kubectl create namespace kali
kubectl apply -f kali.yaml


kubectl create namespace ngi


kubectl apply -f nginx.yaml
kubectl apply -f svcNgi.yaml 

kubectl describe -f svcNgi.yaml
kubectl describe -f nginx.yaml

osm namespace add ngi

kubectl rollout restart deployment nginx2 -n ngi


// now move kali to meshed namespace
kubectl delete -f kali.yaml 
osm namespace add kali
kubectl apply -f kali.yaml 

// cleanUp
osm namespace remove ngi
kubectl delete -f nginx.yaml
kubectl delete  -f svcNgi.yaml 



kubectl expose deployment/nginx2 -n  ngi --port=8888 --target-port=80
kubectl get service -n ngi


osm namespace add ngi
kubectl rollout restart deployment nginx2 -n ngi


osm namespace remove ngi
kubectl delete service nginx2 -n ngi
kubectl delete -f nginx.yaml

# Check which node the service is running
kubectl get pod -o=custom-columns=NODE:.spec.nodeName,NAME:.metadata.name --all-namespaces

kubectl get pod -o=custom-columns=NODE:.spec.nodeName,NAME:.metadata.name --all-namespaces | grep "kali" -A 10

kubectl debug node/aks-nodepool1-92662305-vmss000000 -it --image=mcr.microsoft.com/aks/fundamental/base-ubuntu:v0.0.11 --namespace="kube-system"

# from node s


```sh
node=$(kubectl get nodes -o=jsonpath='{.items[0].metadata.name}')
val=$(echo $node | sed 's/"//g')
kubectl debug node/$val -it --image=mcr.microsoft.com/aks/fundamental/base-ubuntu:v0.0.11 --namespace="kube-system"

apt update -y
apt install iputils-ping -y 
 apt install tcpdump -y
 apt install curl -y
 apt-get install python3


tcpdump -A -s 0 'tcp port 8888 and (((ip[2:2] - ((ip[0]&0xf)<<2)) - ((tcp[12]&0xf0)>>2)) != 0)'


tcpdump -A -s 0 'tcp port 80  and (((ip[2:2] - ((ip[0]&0xf)<<2)) - ((tcp[12]&0xf0)>>2)) != 0)'

tcpdump -A -s 0 'src 10.29.1.49 and tcp port 80  and (((ip[2:2] - ((ip[0]&0xf)<<2)) - ((tcp[12]&0xf0)>>2)) != 0)'


#Get the IP of Kali

kubectl describe pods -n ngi kali3-689f65d675-47fpd

tcpdump -A -s 0 'src 10.29.1.49 and tcp port 80  and (((ip[2:2] - ((ip[0]&0xf)<<2)) - ((tcp[12]&0xf0)>>2)) != 0)'

tcpdump -A -s 0 'src 10.29.1.24 and tcp port 80'

tcpdump -A -s 0 ' src 10.224.0.26 and tcp port 80  and (((ip[2:2] - ((ip[0]&0xf)<<2)) - ((tcp[12]&0xf0)>>2)) != 0)'

 kubectl sniff  my-nginx-cf54cdbf7-gcv9q -n ngi    -f "port 80" -o - | tshark -r -

```

# OSM enable the namespace

osm namespace add ngi
osm namespace remove ngi

# Follow OSM logs
 kubectl logs -l app.kubernetes.io/instance=osm -n "osm-system" -f --max-log-requests=6 -f



 # Demonstrate port mapping
 curl -A "user-agent-name-here" url


 # test UDP service 

 udpsrv.ngi.svc.cluster.local [10.0.88.197] 6000 (?) open

echo "dogs"  |  nc -u udpsrv.ngi.svc.cluster.local 6000

 kubectl logs -l app=udpsrv -n ngi


 # delete stuff

 rm ~/.kube/ -rf
az group delete -g $NAMER -y --no-wait