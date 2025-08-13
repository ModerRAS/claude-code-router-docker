# 多阶段构建优化
FROM node:20-alpine AS builder

# 设置工作目录
WORKDIR /app

# 复制 package.json 和 pnpm-lock.yaml
COPY claude-code-router/package.json claude-code-router/pnpm-lock.yaml ./

# 全局安装 pnpm
RUN npm install -g pnpm

# 安装依赖
RUN pnpm install --frozen-lockfile

# 复制源代码
COPY claude-code-router ./

# 进入 UI 目录并安装依赖
RUN cd ui && npm install

# 构建整个项目
RUN pnpm run build

# 运行阶段
FROM node:20-alpine AS runner

# 设置工作目录
WORKDIR /app

# 创建 non-root 用户
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 claude

# 复制构建产物
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/ui/dist ./ui/dist

# 复制必要的文件
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/CLAUDE.md ./CLAUDE.md

# 设置权限
RUN chown -R claude:nodejs /app
USER claude

# 暴露端口
EXPOSE 3456

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3456', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) }).on('error', () => process.exit(1))"

# 启动路由器服务
CMD ["node", "dist/cli.js", "start"]