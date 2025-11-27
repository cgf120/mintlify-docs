FROM node:18-alpine

# 安装Mintlify CLI
RUN npm install -g mintlify

# 设置工作目录
WORKDIR /app

# 复制项目文件
COPY . .

# 暴露端口
EXPOSE 3000

# 启动Mintlify开发服务器
CMD ["mintlify", "dev", "--port", "3000", "--host", "0.0.0.0"] 