#!/bin/bash

# Bipupu Project Deployment Script
# 用于管理项目的部署、启动、停止等操作

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目根目录
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOCKER_COMPOSE_FILE="${PROJECT_ROOT}/deployment/docker/docker-compose.yml"

# 帮助信息
show_help() {
    echo -e "${BLUE}Bipupu Project Deployment Script${NC}"
    echo -e "${YELLOW}Usage: $0 [COMMAND]${NC}"
    echo ""
    echo "Commands:"
    echo "  up        启动所有服务"
    echo "  down      停止所有服务"
    echo "  restart   重启所有服务"
    echo "  build     构建所有镜像"
    echo "  logs      查看服务日志"
    echo "  status    查看服务状态"
    echo "  init      初始化项目（首次部署）"
    echo "  migrate   运行数据库迁移"
    echo "  backup    备份数据库"
    echo "  clean     清理所有数据和镜像"
    echo "  help      显示帮助信息"
}

# 检查环境
check_env() {
    if [ ! -f "${PROJECT_ROOT}/.env" ]; then
        echo -e "${YELLOW}警告: .env 文件不存在，将使用 .env.example${NC}"
        if [ -f "${PROJECT_ROOT}/.env.example" ]; then
            cp "${PROJECT_ROOT}/.env.example" "${PROJECT_ROOT}/.env"
            echo -e "${GREEN}已创建 .env 文件，请根据需要修改配置${NC}"
        else
            echo -e "${RED}错误: .env.example 文件也不存在${NC}"
            exit 1
        fi
    fi
}

# 启动服务
start_services() {
    echo -e "${BLUE}正在启动服务...${NC}"
    cd "${PROJECT_ROOT}"
    docker-compose -f "${DOCKER_COMPOSE_FILE}" up -d
    echo -e "${GREEN}服务启动完成！${NC}"
    echo -e "${YELLOW}API 文档: http://localhost:8084/docs${NC}"
    echo -e "${YELLOW}健康检查: http://localhost:8084/health${NC}"
}

# 停止服务
stop_services() {
    echo -e "${BLUE}正在停止服务...${NC}"
    cd "${PROJECT_ROOT}"
    docker-compose -f "${DOCKER_COMPOSE_FILE}" down
    echo -e "${GREEN}服务已停止${NC}"
}

# 重启服务
restart_services() {
    echo -e "${BLUE}正在重启服务...${NC}"
    cd "${PROJECT_ROOT}"
    docker-compose -f "${DOCKER_COMPOSE_FILE}" restart
    echo -e "${GREEN}服务重启完成${NC}"
}

# 构建镜像
build_images() {
    echo -e "${BLUE}正在构建镜像...${NC}"
    cd "${PROJECT_ROOT}"
    docker-compose -f "${DOCKER_COMPOSE_FILE}" build --no-cache
    echo -e "${GREEN}镜像构建完成${NC}"
}

# 查看日志
show_logs() {
    echo -e "${BLUE}正在查看日志...${NC}"
    cd "${PROJECT_ROOT}"
    docker-compose -f "${DOCKER_COMPOSE_FILE}" logs -f
}

# 查看状态
show_status() {
    echo -e "${BLUE}服务状态：${NC}"
    cd "${PROJECT_ROOT}"
    docker-compose -f "${DOCKER_COMPOSE_FILE}" ps
}

# 初始化项目
init_project() {
    echo -e "${BLUE}正在初始化项目...${NC}"
    check_env
    
    # 构建镜像
    build_images
    
    # 启动数据库
    echo -e "${BLUE}正在启动数据库...${NC}"
    docker-compose -f "${DOCKER_COMPOSE_FILE}" up -d db redis
    
    # 等待数据库就绪
    echo -e "${BLUE}等待数据库就绪...${NC}"
    sleep 10
    
    # 运行数据库迁移
    echo -e "${BLUE}运行数据库迁移...${NC}"
    docker-compose -f "${DOCKER_COMPOSE_FILE}" run --rm backend alembic upgrade head
    
    # 启动所有服务
    start_services
    
    echo -e "${GREEN}项目初始化完成！${NC}"
}

# 数据库迁移
run_migrate() {
    echo -e "${BLUE}正在运行数据库迁移...${NC}"
    cd "${PROJECT_ROOT}"
    docker-compose -f "${DOCKER_COMPOSE_FILE}" run --rm backend alembic upgrade head
    echo -e "${GREEN}数据库迁移完成${NC}"
}

# 备份数据库
backup_db() {
    echo -e "${BLUE}正在备份数据库...${NC}"
    cd "${PROJECT_ROOT}"
    BACKUP_FILE="backup_$(date +%Y%m%d_%H%M%S).sql"
    docker-compose -f "${DOCKER_COMPOSE_FILE}" exec db pg_dump -U postgres bipupu > "${PROJECT_ROOT}/${BACKUP_FILE}"
    echo -e "${GREEN}数据库备份完成: ${BACKUP_FILE}${NC}"
}

# 清理所有
clean_all() {
    echo -e "${YELLOW}警告: 这将删除所有数据和镜像！${NC}"
    read -p "确定要继续吗? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}正在清理...${NC}"
        cd "${PROJECT_ROOT}"
        docker-compose -f "${DOCKER_COMPOSE_FILE}" down -v --remove-orphans
        docker system prune -af
        echo -e "${GREEN}清理完成${NC}"
    else
        echo -e "${YELLOW}操作已取消${NC}"
    fi
}

# 主逻辑
main() {
    case "${1:-help}" in
        up)
            check_env
            start_services
            ;;
        down)
            stop_services
            ;;
        restart)
            restart_services
            ;;
        build)
            build_images
            ;;
        logs)
            show_logs
            ;;
        status)
            show_status
            ;;
        init)
            init_project
            ;;
        migrate)
            run_migrate
            ;;
        backup)
            backup_db
            ;;
        clean)
            clean_all
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo -e "${RED}错误: 未知命令 '${1}'${NC}"
            show_help
            exit 1
            ;;
    esac
}

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    echo -e "${RED}错误: Docker 未安装${NC}"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}错误: Docker Compose 未安装${NC}"
    exit 1
fi

# 运行主函数
main "$@"