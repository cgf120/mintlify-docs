#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 检查Docker和Docker Compose是否安装
check_prerequisites() {
    print_info "检查环境依赖..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker 未安装，请先安装 Docker"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose 未安装，请先安装 Docker Compose"
        exit 1
    fi
    
    print_success "环境检查通过"
}

# 拉取最新代码
update_code() {
    print_info "拉取最新代码..."
    
    if [ -d ".git" ]; then
        git pull
        if [ $? -eq 0 ]; then
            print_success "代码更新完成"
        else
            print_warning "代码更新失败，继续使用当前版本"
        fi
    else
        print_warning "非Git仓库，跳过代码更新"
    fi
}

# 停止旧服务
stop_old_service() {
    print_info "停止旧服务..."
    docker-compose down
    print_success "旧服务已停止"
}

# 启动新服务
start_service() {
    print_info "启动新服务..."
    docker-compose up -d --build
    
    if [ $? -eq 0 ]; then
        print_success "服务启动命令执行完成"
    else
        print_error "服务启动失败"
        exit 1
    fi
}

# 等待服务就绪
wait_for_service() {
    print_info "等待服务启动..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s http://localhost:3000 > /dev/null 2>&1; then
            print_success "服务已就绪"
            return 0
        fi
        
        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    print_warning "服务启动超时，请检查日志"
    return 1
}

# 检查服务状态
check_service_status() {
    print_info "检查服务状态..."
    
    local status=$(docker-compose ps --services --filter "status=running" | wc -l)
    
    if [ $status -gt 0 ]; then
        print_success "服务运行正常"
        echo ""
        print_info "服务信息："
        docker-compose ps
        echo ""
        print_success "🎉 部署成功！"
        print_info "访问地址：http://localhost:3000"
        print_info "移动端访问：http://你的服务器IP:3000"
        echo ""
        print_info "服务管理命令："
        echo "  查看日志: docker-compose logs -f docs"
        echo "  停止服务: docker-compose down"
        echo "  重启服务: docker-compose restart"
        return 0
    else
        print_error "服务启动失败"
        print_info "查看错误日志："
        docker-compose logs docs
        return 1
    fi
}

# 主函数
main() {
    echo ""
    print_info "开始部署晨羽智云API文档..."
    echo ""
    
    # 检查环境
    check_prerequisites
    
    # 更新代码
    update_code
    
    # 停止旧服务
    stop_old_service
    
    # 启动新服务
    start_service
    
    # 等待服务就绪
    wait_for_service
    
    # 检查服务状态
    check_service_status
    
    if [ $? -eq 0 ]; then
        echo ""
        print_success "部署完成！"
        exit 0
    else
        echo ""
        print_error "部署失败！"
        exit 1
    fi
}

# 处理中断信号
trap 'echo ""; print_warning "部署被中断"; exit 1' INT

# 执行主函数
main "$@" 