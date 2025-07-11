# GitOps Configuration with ArgoCD

这个仓库包含了使用ArgoCD实现GitOps CD部分的完整配置，支持开发和生产两个环境。

## 目录结构

```
gitops/
├── argocd/                          # ArgoCD配置文件
│   ├── applications/                # 应用程序配置
│   │   ├── dev-app.yaml            # 开发环境应用
│   │   └── prod-app.yaml           # 生产环境应用
│   ├── projects/                   # 项目配置
│   │   └── myapp-project.yaml      # 项目权限和策略
│   └── applicationsets/            # ApplicationSet配置
│       └── myapp-applicationset.yaml # 多环境自动管理
└── manifests/                      # Kubernetes清单文件
    ├── base/                       # 基础配置
    │   ├── kustomization.yaml
    │   ├── deployment.yaml
    │   ├── service.yaml
    │   ├── configmap.yaml
    │   └── secret.yaml
    └── overlays/                   # 环境特定配置
        ├── dev/                    # 开发环境
        │   ├── kustomization.yaml
        │   ├── namespace.yaml
        │   ├── deployment-patch.yaml
        │   ├── configmap-patch.yaml
        │   └── ingress.yaml
        └── prod/                   # 生产环境
            ├── kustomization.yaml
            ├── namespace.yaml
            ├── deployment-patch.yaml
            ├── configmap-patch.yaml
            ├── service-patch.yaml
            ├── ingress.yaml
            ├── hpa.yaml
            ├── pdb.yaml
            └── networkpolicy.yaml
```

## 环境配置

### 开发环境 (dev)
- **命名空间**: `myapp-dev`
- **副本数**: 1
- **资源限制**: 较低的CPU和内存配置
- **日志级别**: DEBUG
- **自动同步**: 启用
- **自愈**: 启用
- **数据库**: H2内存数据库
- **缓存**: 内存缓存

### 生产环境 (prod)
- **命名空间**: `myapp-prod`
- **副本数**: 3（支持HPA自动扩缩容到10个）
- **资源限制**: 较高的CPU和内存配置
- **日志级别**: WARN
- **自动同步**: 手动触发
- **自愈**: 禁用（需要手动干预）
- **数据库**: PostgreSQL
- **缓存**: Redis集群
- **安全**: 包含NetworkPolicy、PodDisruptionBudget等

## 部署步骤

### 1. 安装ArgoCD

```bash
# 创建ArgoCD命名空间
kubectl create namespace argocd

# 安装ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 等待ArgoCD启动
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
```

### 2. 配置ArgoCD访问

```bash
# 获取初始密码
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# 端口转发访问ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

### 3. 部署项目配置

```bash
# 应用项目配置
kubectl apply -f argocd/projects/myapp-project.yaml
```

### 4. 部署应用程序

#### 方式一：使用单独的Application配置

```bash
# 部署开发环境
kubectl apply -f argocd/applications/dev-app.yaml

# 部署生产环境
kubectl apply -f argocd/applications/prod-app.yaml
```

#### 方式二：使用ApplicationSet（推荐）

```bash
# 使用ApplicationSet自动管理多环境
kubectl apply -f argocd/applicationsets/myapp-applicationset.yaml
```

## 配置说明

### 镜像标签管理
- **开发环境**: 使用 `dev-latest` 标签
- **生产环境**: 使用具体版本标签如 `v1.0.0`

### 同步策略
- **开发环境**: 自动同步，启用自愈和修剪
- **生产环境**: 手动同步，禁用自愈，启用修剪

### 安全配置
- 生产环境包含Pod安全策略
- NetworkPolicy限制网络访问
- PodDisruptionBudget确保高可用性
- 资源限制和请求配置

### 监控和可观测性
- 健康检查和就绪检查
- Prometheus指标暴露
- 结构化日志配置

## 自定义配置

### 修改仓库地址
在以下文件中更新你的Git仓库地址：
- `argocd/applications/dev-app.yaml`
- `argocd/applications/prod-app.yaml`
- `argocd/applicationsets/myapp-applicationset.yaml`
- `argocd/projects/myapp-project.yaml`

### 修改域名
在以下文件中更新你的域名：
- `manifests/overlays/dev/ingress.yaml`
- `manifests/overlays/prod/ingress.yaml`

### 修改应用名称
全局搜索替换 `myapp` 为你的应用名称。

### 修改密钥
更新 `manifests/base/secret.yaml` 中的Base64编码密钥。

## 最佳实践

1. **版本控制**: 所有配置文件都应该版本控制
2. **环境隔离**: 使用不同的命名空间和配置
3. **安全**: 生产环境使用更严格的安全策略
4. **监控**: 配置适当的监控和告警
5. **备份**: 定期备份重要配置和数据
6. **测试**: 在开发环境充分测试后再部署到生产环境

## 故障排除

### 查看应用状态
```bash
# 查看ArgoCD应用状态
kubectl get applications -n argocd

# 查看具体应用详情
kubectl describe application myapp-dev -n argocd
```

### 查看Pod状态
```bash
# 查看开发环境Pod
kubectl get pods -n myapp-dev

# 查看生产环境Pod
kubectl get pods -n myapp-prod
```

### 查看日志
```bash
# 查看应用日志
kubectl logs -f deployment/myapp -n myapp-dev

# 查看ArgoCD日志
kubectl logs -f deployment/argocd-application-controller -n argocd
```

## 扩展功能

- **多集群部署**: 配置多个Kubernetes集群
- **Helm支持**: 集成Helm Charts
- **Webhook**: 配置Git webhook自动触发同步
- **RBAC**: 配置更细粒度的权限控制
- **通知**: 配置Slack/Email通知