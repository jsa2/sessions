# Create directory for dump
mkdir dump;cd dump

# Dump selected in all namespaces
unset IFS
C=0
svcs=(pods deployment services)
for OBJ in "${svcs[@]}"
do
   for DEF in $( kubectl get --show-kind --ignore-not-found $OBJ -o jsonpath='{range .items[*]}{.metadata.name},{.metadata.namespace}{"\n"}{end}'  --all-namespaces )
   do
   mkdir -p $OBJ
   unset IFS
    let C=C+1
    echo $C
    echo $DEF
      arrIN=(${DEF//,/ })

          echo ${arrIN[0]}  ${arrIN[1]} 
          kubectl get $OBJ -n ${arrIN[0]} -o yaml --namespace ${arrIN[1]}   > $OBJ/${arrIN[0]}.yaml
   done
done