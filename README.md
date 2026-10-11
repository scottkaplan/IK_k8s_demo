# IK-k8s-demo

## Dockerfile demo

- docker/Dockerfile
- docker build -t demo .
- docker images
- docker run -d --name demo -p 80:80 demo:latest
- docker ps
- http://10.1.2.99
- docker stop demo
- docker image rm demo # Nope, image is still being used by a container (Like a stopped VM using an AMI)
- docker ps -a # container is still on list, but exited
- docker container rm demo
- docker ps -a # Now it’s gone
- docker image rm demo # we can delete the image


## Container Repository Demo

- hub.docker.com
- Create demo repository
- https://hub.docker.com/repository/docker/scottkaplan/
- docker push demo # fails because we don’t have access to the root namespace of docker hub
- docker push scottkaplan/demo # This fails because demo doesn’t have ‘scottkaplan/’ prefix
- docker images
- docker tag demo scottkaplan/demo # Create another tag pointing to the same container
- docker images
- docker push scottkaplan/demo


## Create IaC Footprint

- cd terraform
- terraform apply

## Initialize AWS auth

- aws eks update-kubeconfig --region us-west-1 --name demo

## Pod Basics

- cd basic
- kubectl get nodes
- kubectl get pods
- kubectl apply -f app.yml
- kubectl get deploy hello-deploy
- kubectl describe deploy hello-deploy
- kubectl get pods
- kubectl port-forward --address 0.0.0.0 pod/hello-deploy-85fb59464d-khzkx 31416:8080


## Networking

- kubectl apply -f lb.yml
- kubectl get svc lb-svc
- # this spins up an AWS load balancer
- # Note AWS specific annotations
- kubectl apply -f lb.yml
- Notice the annotations for the AWS specific LB parameters
- Listen on port 8080 and send incoming requests to any pod with the label app=hello-world
- Show the AWS LB in the AWS console
- Open a browser and visit <LB URL>:8080

## File System

- AWS
  - Create EFS volume
    - Name: efs-demo
  - Put File system ID in pv.yml
  - From IAM -> Roles, search for role eks-node-group-nodes and add 2 perms 
    - Add Permissions -> Attach Policy -> search for AmazonElasticFileSystemClientFullAccess (AWS managed), click box, Add permission
    - Add Permissions -> client inline Policy -> choose service ec2 -> search for DescribeAvailabilityZones, click box
      - Policy name: listaz
  - EFS -> Add-ons -> Get Add-ons: Check Amazon EFS CSI Drive addon
  - Allow inbound NFS for VPC default security group
    - VPC -> Security Groups
    - Find default for IK VPC
    - Edit incoming rule
    - Add rule: NFS to any IPv4

- kubectl
  - kubectl get sc
  - kubectl describe sc gp2
  - kubectl apply -f pv.yml
  - kubectl get pv
  - kubectl apply -f pvc.yml
  - kubectl get pvc
  - cat efs-pod.yml
  - kubectl apply -f efs-pod.yml
  - kubectl describe pods efs-app
  - kubectl exec -ti efs-app -- tail -f /data/out.txt


## Namespace

- kubectl get ns

# Create the namespace imperatively
- kubectl create ns hydra
- kubectl get ns

# Create the namespace declaratively
- kubectl apply -f shield-ns.yml
- kubectl get ns
- kubectl apply -f shield-app.yml
- kubectl get pods # Nope, not here, this is the default namespace
- kubectl get pods --all-namespaces
- kubectl get pods -n shield
- kubectl get svc -n shield


## Configmap

- kubectl apply -f multimap.yml
- kubectl describe cm multimap

- pass config map in the environment
  - kubectl apply -f envpod.yml
  - kubectl exec envpod -- env | grep NAME

- Mount the config on the file system where each file has the key as the file name and the value as the file contents
  - kubectl apply -f cmpod.yml
  - kubectl exec cmvol -- ls /etc/name
  - kubectl exec cmvol -- cat /etc/name/given


## Secrets (aren't)

- kubectl apply -f tkb-secret.yml
- kubectl get secret
- kubectl describe secret/tkb-secret

- # Pass secrets by mounting a volume:
- kubectl apply -f secretpod.yml
- kubectl exec secret-pod -- ls /etc/tkb
- kubectl exec secret-pod -- cat /etc/tkb/password

- # Secrets aren’t secure
- echo UGFzc3dvcmQxMjM= | base64 -d


## Health Checks

- exec check
  - kubectl apply -f exec-liveness.yml
  - kubectl describe pod liveness-exec
  - kubectl get pods liveness-exec
- HTTP check
  - kubectl apply -f http-liveness.yml
  - kubectl port-forward --address 0.0.0.0 pod/liveness-http 31416:8080
  - http://10.1.2.99:31416/healthz
- TCP check for both liveness and readiness
  - kubectl apply -f tcp-liveness-readiness.yaml
  - kubectl describe pod goproxy

## Horizontal Pod Autoscaler

Based on https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/
- Configure metrics server
  - kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
- The webserver we are going to autoscale:
  - kubectl apply -f php-apache.yaml
- kubectl autoscale deployment php-apache --cpu-percent=50 --min=1 --max=10
- kubectl get hpa
- load.sh &
- kubectl get hpa
- kubectl get pods
- Add more nodes with terraform/2-eks.tf
