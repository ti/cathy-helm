# Helm Charts For Continuous Development

## 操作步骤 （以AWS为例）

#### 1. 创建EKS集群，记录集群名称，比如：orbit
#### 2. 创建EFS，记录ID, 比如：fs-03d82029d8d02d8b8
#### 3. 创建FSx，记录ID 和 mountname， 比如：fs-0c76e579372bc4dfa， sp5etb4v
#### 4. 创建S3，记录ID，比如：xlab-eks
#### 4. EKS安装插件：
   Amazon EFS CSI Driver, Amazon VPC CNI, Mountpoint for Amazon S3 CSI Driver, Amazon EKS Pod Identity Agent, kube-proxy
   CoreDNS,Cert Manager,Amazon FSx CSI driver,Metrics Server,

需要自定义的Advanced configuration YAML文件如下：
cert-manager:

```yaml
extraArgs:
  - --enable-gateway-api=true
```
VPC-CNI：
如果POD子网和正式子网不一致，需要配置如下：
```yaml
env:
  AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG: "true"
  AWS_VPC_K8S_CNI_EXTERNALSNAT: "false"
  ENI_CONFIG_LABEL_DEF: "topology.kubernetes.io/zone"
  AWS_VPC_K8S_CNI_LOGLEVEL: "DEBUG"
  ENABLE_SUBNET_DISCOVERY: "true"

eniConfig:
  create: true
  region: "us-west-2"
  subnets:
    us-west-2c:
      id: "subnet-0e317eaea01f17f28"
    us-west-2d:
      id: "subnet-003b397d0c1f2e4f2"
```

aws-mountpoint-s3-csi-driver：

```yaml
node:
  tolerateAllTaints: true
  nodeSelector: null
  podInfoOnMountCompat:
    enable: false
```

kube-proxy:

```yaml
podAnnotations: {}
podLabels: {}
```
metrics-server:
```yaml
nodeSelector:
  usage: system
```

#### 5. 创建静态节点组：static，用于长期稳定的负载, 要求如下：

```bash
Account ID: 867344450900
role: NxlabsEksNodeGroup
label: type=cpu
tolerations:
  - key: "compute"
    operator: "Equal"
    value: "static"
    effect: "NoSchedule"
```

#### 7. GIT仓库中环境变量如下：
AWS_ACCOUNT_ID: 867344450900
AWS_REGION: us-west-2
CLUSTER: orbit
NAMESPACE: aws300

### 8. 映射域名

