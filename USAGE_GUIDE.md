# ArgoCD 使用指南

既然你已经安装了ArgoCD，以下是如何使用现有配置的步骤：

## 快速开始

### 1. 应用配置到ArgoCD

```bash
# 进入项目目录
cd /Users/mac/Data/codes/yaml/gitops

# 应用项目配置
kubectl apply -f argocd/projects/myapp-project.yaml

# 应用ApplicationSet（推荐，会自动创建dev应用）
kubectl apply -f argocd/applicationsets/myapp-applicationset.yaml
```

### 2. 验证配置是否生效

```bash
# 查看应用状态
kubectl get applications -n argocd

# 查看ApplicationSet状态
kubectl get applicationsets -n argocd
```

你应该看到类似输出：
```
NAME        SYNC STATUS   HEALTH STATUS   AGE
myapp-dev   Synced        Healthy         1m
myapp-prod  OutOfSync     Healthy         1m
```

### 3. 访问ArgoCD UI

```bash
# 端口转发（在新终端窗口运行）
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

然后访问：https://localhost:8080

### 4. 获取登录密码（如果需要）

```bash
# 获取admin密码
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo
```

## 同步应用

### 在UI中同步
1. 登录ArgoCD UI
2. 点击应用名称（myapp-dev 或 myapp-prod）
3. 点击 "SYNC" 按钮
4. 选择同步选项，点击 "SYNCHRONIZE"

### 命令行同步

```bash
# 同步开发环境
kubectl patch application myapp-dev -n argocd --type merge --patch '{"operation":{"sync":{}}}'

# 同步生产环境
kubectl patch application myapp-prod -n argocd --type merge --patch '{"operation":{"sync":{}}}'
```

## 检查部署结果

```bash
# 检查开发环境
kubectl get all -n myapp-dev

# 检查生产环境
kubectl get all -n myapp-prod
```

## 更新应用

当你修改了 `manifests/` 目录中的文件：

1. **提交到Git仓库**：
   ```bash
   git add .
   git commit -m "Update application manifests"
   git push
   ```

2. **触发同步**：
   - 开发环境会自动同步（配置了自动同步）
   - 生产环境需要手动同步（安全考虑）

## 常用操作

### 查看应用详情
```bash
kubectl describe application myapp-dev -n argocd
```

### 查看同步历史
```bash
kubectl get application myapp-dev -n argocd -o yaml
```

### 强制刷新
```bash
kubectl patch application myapp-dev -n argocd --type merge --patch '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}'
```

### 删除应用
```bash
# 删除单个应用
kubectl delete application myapp-dev -n argocd

# 删除ApplicationSet（会删除所有相关应用）
kubectl delete applicationset myapp-environments -n argocd
```

## 故障排除

### 应用显示OutOfSync
- 检查Git仓库是否可访问
- 检查路径是否正确
- 手动触发同步

### 应用显示Degraded
```bash
# 查看具体错误
kubectl describe application myapp-dev -n argocd

# 查看Pod状态
kubectl get pods -n myapp-dev
kubectl describe pod <pod-name> -n myapp-dev
```

### 权限问题
```bash
# 检查项目权限
kubectl describe appproject myapp-project -n argocd
```

## 脚本快捷方式

你也可以使用提供的脚本：

```bash
# 部署项目配置
./deploy.sh deploy-project

# 部署ApplicationSet
./deploy.sh deploy-appset

# 查看状态
./deploy.sh status

# 访问UI
./deploy.sh ui
```

现在你可以开始使用ArgoCD管理你的应用了！