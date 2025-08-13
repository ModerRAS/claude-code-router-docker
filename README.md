# Claude Code Router Docker

这是 [claude-code-router](https://github.com/musistudio/claude-code-router) 的 Docker 化版本，通过 GitHub Actions 自动构建并推送到 GitHub Container Registry。

## 功能特性

- 🐳 **多阶段构建**: 优化的 Docker 镜像，减小镜像体积
- 🔒 **安全**: 使用 non-root 用户运行容器
- 🏥 **健康检查**: 内置健康检查机制
- 🔄 **自动构建**: GitHub Actions 自动构建多平台镜像（linux/amd64, linux/arm64）
- 📦 **缓存优化**: 利用 BuildKit 缓存加速构建
- ⚙️ **配置管理**: 提供便捷的配置管理脚本
- 📊 **日志管理**: 自动挂载日志目录，便于管理和查看
- 🚀 **开发支持**: 提供开发环境配置，支持调试和热重载

## 快速开始

### 使用 Docker 运行

```bash
# 从 GitHub Container Registry 拉取镜像
docker pull ghcr.io/moderras/claude-code-router-docker:latest

# 运行容器
docker run -d \
  --name claude-code-router \
  -p 3456:3456 \
  -v $(pwd)/config:/root/.claude-code-router \
  -v $(pwd)/logs:/root/.claude-code-router/logs \
  ghcr.io/moderras/claude-code-router-docker:latest
```

### 使用 Docker Compose

```bash
# 生产环境
docker-compose up -d

# 开发环境（包含调试支持）
docker-compose -f docker-compose.dev.yml up -d
```

## 配置

### 环境变量

容器支持以下环境变量配置：

- `PORT`: 服务端口（默认：3456）
- `NODE_ENV`: 运行环境（默认：production）

### 配置文件管理

项目提供了便捷的配置管理脚本：

```bash
# 初始化配置文件
./scripts/config.sh init

# 编辑配置文件
./scripts/config.sh edit

# 查看当前配置
./scripts/config.sh show

# 验证配置文件格式
./scripts/config.sh validate

# 更新容器配置
./scripts/config.sh copy-to-container

# 从容器复制配置
./scripts/config.sh copy-from-container

# 重置为示例配置
./scripts/config.sh reset
```

#### 手动配置文件管理

配置文件挂载到 `/root/.claude-code-router` 目录：

```bash
# 创建配置目录
mkdir -p config

# 复制示例配置文件
cp claude-code-router/config.example.json config/config.json

# 编辑配置文件
vim config/config.json

# 使用 Docker Compose 时配置会自动挂载
```

## 使用方法

### 检查服务状态

```bash
docker exec claude-code-router ccr status
```

### 启动服务

```bash
docker exec claude-code-router ccr start
```

### 停止服务

```bash
docker exec claude-code-router ccr stop
```

### 使用路由器

```bash
docker exec claude-code-router ccr code "your prompt here"
```

## 开发

### 本地构建

```bash
# 构建镜像
docker build -t claude-code-router .

# 运行容器
docker run -d --name claude-code-router -p 3456:3456 claude-code-router
```

### 使用子模块

项目使用 Git 子模块管理 claude-code-router 源码：

```bash
# 初始化子模块
git submodule init
git submodule update

# 或者递归克隆
git clone --recursive https://github.com/ModerRAS/claude-code-router-docker.git
```

## 自动构建

### GitHub Actions 工作流

项目包含以下 GitHub Actions 工作流：

- **分支推送**: 自动构建并推送镜像到 GitHub Container Registry
- **Pull Request**: 构建镜像但不推送
- **发布版本**: 自动构建并推送版本标签镜像

### 镜像标签

- `latest`: 最新版本（默认分支）
- `v1.0.0`: 具体版本标签
- `v1`: 主版本标签
- `pr-123`: Pull Request 标签

## 故障排除

### 常见问题

1. **权限问题**: 确保配置目录有正确的权限
   ```bash
   chmod -R 755 ~/.claude-code-router
   ```

2. **端口冲突**: 检查 3456 端口是否被占用
   ```bash
   netstat -tulpn | grep :3456
   ```

3. **配置文件错误**: 检查配置文件格式是否正确
   ```bash
   docker exec claude-code-router cat /root/.claude-code-router/config.json
   ```

### 日志查看

```bash
# 查看容器日志
docker logs claude-code-router

# 实时查看日志
docker logs -f claude-code-router
```

## 贡献

欢迎提交 Issue 和 Pull Request！

## 许可证

MIT License - 详见 [LICENSE](claude-code-router/LICENSE) 文件