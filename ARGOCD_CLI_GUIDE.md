# ArgoCD CLI 使用指南

你说得对！除了kubectl命令，还可以使用ArgoCD CLI工具来管理应用程序，这样更加方便和直观。

## 1. 安装ArgoCD CLI

### macOS 安装方法：

```bash
# 方法1：使用Homebrew（推荐）
brew install argocd

# 方法2：直接下载
curl -sSL -o argocd-darwin-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-darwin-amd64
sudo install -m 555 argocd-darwin-amd64 /usr/local/bin/argocd
rm argocd-darwin-amd64

# 方法3：如果是Apple Silicon (M1/M2)
curl -sSL -o argocd-darwin-arm64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-darwin-arm64
sudo install -m 555 argocd-darwin-arm64 /usr/local/bin/argocd
rm argocd-darwin-arm64
```

## 2. 登录ArgoCD

### 获取ArgoCD服务器地址和密码：

```bash
# 端口转发（在后台运行）
kubectl port-forward svc/argocd-server -n argocd 8080:443 &

# 获取初始密码
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "ArgoCD Password: $ARGOCD_PASSWORD"

# 登录ArgoCD
argocd login localhost:8080 --username admin --password $ARGOCD_PASSWORD --insecure
```

## 3. 使用ArgoCD CLI管理应用

### 应用配置到ArgoCD：

```bash
# 首先应用kubectl配置（项目和ApplicationSet）
kubectl apply -f argocd/projects/myapp-project.yaml
kubectl apply -f argocd/applicationsets/myapp-applicationset.yaml

# 或者使用argocd命令创建应用
argocd app create myapp-dev \
  --repo https://github.com/xinxin20020807/gitops.git \
  --path manifests/overlays/dev \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace myapp-dev \
  --project myapp-project \
  --sync-policy automated \
  --auto-prune \
  --self-heal

argocd app create myapp-prod \
  --repo https://github.com/xinxin20020807/gitops.git \
  --path manifests/overlays/prod \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace myapp-prod \
  --project myapp-project
```

### 查看应用状态：

```bash
# 列出所有应用
argocd app list

# 查看特定应用详情
argocd app get myapp-dev

# 查看应用同步状态
argocd app sync myapp-dev --dry-run
```

### 同步应用：

```bash
# 同步开发环境
argocd app sync myapp-dev

# 同步生产环境
argocd app sync myapp-prod

# 强制同步（忽略差异）
argocd app sync myapp-dev --force

# 同步并修剪资源
argocd app sync myapp-dev --prune
```

### 查看应用历史：

```bash
# 查看同步历史
argocd app history myapp-dev

# 回滚到特定版本
argocd app rollback myapp-dev <revision-id>
```

### 查看应用差异：

```bash
# 查看当前状态与Git的差异
argocd app diff myapp-dev

# 查看本地文件与集群的差异
argocd app diff myapp-dev --local manifests/overlays/dev
```

## 4. 常用ArgoCD CLI命令

### 应用管理：

```bash
# 创建应用
argocd app create <app-name> --repo <repo-url> --path <path> --dest-server <server> --dest-namespace <namespace>

# 删除应用
argocd app delete myapp-dev

# 设置应用参数
argocd app set myapp-dev --parameter image.tag=v1.2.0

# 启用自动同步
argocd app set myapp-dev --sync-policy automated

# 禁用自动同步
argocd app unset myapp-dev --sync-policy
```

### 项目管理：

```bash
# 列出项目
argocd proj list

# 查看项目详情
argocd proj get myapp-project

# 创建项目
argocd proj create myapp-project
```

### 仓库管理：

```bash
# 添加Git仓库
argocd repo add https://github.com/xinxin20020807/gitops.git

# 列出仓库
argocd repo list

# 测试仓库连接
argocd repo get https://github.com/xinxin20020807/gitops.git
```

## 5. 实际使用流程

### 完整的部署流程：

```bash
# 1. 登录ArgoCD
argocd login localhost:8080 --username admin --password $ARGOCD_PASSWORD --insecure

# 2. 添加Git仓库（如果需要）
argocd repo add https://github.com/xinxin20020807/gitops.git

# 3. 应用kubectl配置（推荐使用ApplicationSet）
kubectl apply -f argocd/projects/myapp-project.yaml
kubectl apply -f argocd/applicationsets/myapp-applicationset.yaml

# 4. 查看应用状态
argocd app list

# 5. 同步应用
argocd app sync myapp-dev
argocd app sync myapp-prod

# 6. 验证部署
kubectl get all -n myapp-dev
kubectl get all -n myapp-prod
```

### 日常维护：

```bash
# 查看应用状态
argocd app get myapp-dev

# 查看差异
argocd app diff myapp-dev

# 同步更新
argocd app sync myapp-dev

# 查看日志
argocd app logs myapp-dev
```

## 6. 脚本集成

你也可以修改 `deploy.sh` 脚本来集成ArgoCD CLI命令：

```bash
# 在deploy.sh中添加argocd命令支持
# 例如：
./deploy.sh argocd-login    # 登录ArgoCD
./deploy.sh argocd-sync     # 同步所有应用
./deploy.sh argocd-status   # 查看应用状态
```

## 7. 故障排除

```bash
# 查看ArgoCD服务器信息
argocd version

# 查看应用事件
argocd app get myapp-dev --show-operation

# 查看应用资源
argocd app resources myapp-dev

# 强制刷新应用
argocd app get myapp-dev --refresh
```

现在你可以使用ArgoCD CLI来更方便地管理你的GitOps应用了！