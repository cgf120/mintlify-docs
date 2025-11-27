# 晨羽智云API文档 - 一键部署

## 🚀 快速部署

```bash
# 1. 克隆代码
git clone https://github.com/your-org/chenyu-api-docs.git
cd chenyu-api-docs

# 2. 一键部署
./deploy.sh

# 3. 访问文档
# 浏览器打开: http://localhost:3000
```

## 📋 环境要求

- Docker
- Docker Compose  
- Git

## 🔧 手动部署

```bash
# 启动服务
docker-compose up -d

# 查看状态  
docker-compose ps

# 查看日志
docker-compose logs -f docs
```

## 🛠 服务管理

```bash
# 停止服务
docker-compose down

# 重启服务
docker-compose restart

# 更新部署
git pull && docker-compose up -d --build
```

## ⚙️ 配置修改

### 端口配置
默认端口：`3000`，修改 `docker-compose.yml`：
```yaml
ports:
  - "8080:3000"  # 改为8080端口
```

### 生产环境
```yaml
services:
  docs:
    ports:
      - "80:3000"  # 使用80端口
```

## 🔍 故障排除

**端口被占用**
```bash
lsof -i :3000  # 查看端口占用
```

**服务启动失败**  
```bash
docker-compose logs docs  # 查看日志
docker-compose up --build # 重新构建
```

**文档不显示**
```bash
cat mint.json              # 检查配置
docker-compose restart docs # 重启服务
```

## 📁 核心文件

```
chenyu-api-docs/
├── Dockerfile           # Docker镜像配置
├── docker-compose.yml   # 容器编排配置  
├── deploy.sh           # 一键部署脚本
└── mint.json           # Mintlify配置
```

## 🎯 特性

- ✅ 一命令部署 (`./deploy.sh`)
- ✅ 自动健康检查
- ✅ 支持热更新
- ✅ 轻量级镜像 (node:18-alpine)
- ✅ HTTP服务 (端口3000)

## 🌐 访问地址

- **本地**: http://localhost:3000
- **服务器**: http://YOUR_SERVER_IP:3000
- **移动端**: 同服务器地址

---

**极简部署，开箱即用！** 🎉 