# get TCPDump for meshed pod

node=$(kubectl get pod kali2 -n kali2   -o=jsonpath='{.spec.nodeName}')
podIp=$(kubectl get pod kali2 -n kali2   -o=jsonpath='{.status.podIP}')
kubectl describe pod kali2 -n kali2 
echo $podIp $node
kubectl debug node/$node -it --image=mcr.microsoft.com/aks/fundamental/base-ubuntu:v0.0.11 --namespace="kube-system"

apt update -y
apt install tcpdump -y


# on another window
kubectl exec --stdin --tty kali2 -n kali2 -- /bin/bash

echo "
tcpdump -i any  -A -s 0 'host ${podIp} and tcp port 80  and (((ip[2:2] - ((ip[0]&0xf)<<2)) - ((tcp[12]&0xf0)>>2)) != 0)' 
"

echo "
tcpdump -i any  -A -s 0 'host ${podIp}  and (((ip[2:2] - ((ip[0]&0xf)<<2)) - ((tcp[12]&0xf0)>>2)) != 0)' 
"

echo "
tcpdump -i any -A -s 0 'host ${podIp}  and udp port 6000' 
"


# unmeshed


