FROM node:20.17-alpine

# 安装 Mint CLI
RUN npm install -g mint

# 设置工作目录
WORKDIR /app

# 复制项目文件
COPY . .

# 暴露端口
EXPOSE 3000

# 启动 Mintlify 开发服务器
CMD ["mint", "dev", "--port", "3000", "--host", "0.0.0.0", "--no-open"]
