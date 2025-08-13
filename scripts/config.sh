#!/bin/bash

# Claude Code Router Docker 配置管理脚本
# 使用方法: ./scripts/config.sh [命令] [选项]

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 默认配置
CONTAINER_NAME="claude-code-router"
CONFIG_DIR="${PWD}/config"
CONFIG_FILE="${CONFIG_DIR}/config.json"
CUSTOM_ROUTER_FILE="${CONFIG_DIR}/custom-router.js"
EXAMPLE_CONFIG_FILE="claude-code-router/config.example.json"
EXAMPLE_CUSTOM_ROUTER_FILE="claude-code-router/custom-router.example.js"

# 打印带颜色的信息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 显示帮助信息
show_help() {
    echo "Claude Code Router Docker 配置管理脚本"
    echo ""
    echo "使用方法:"
    echo "  $0 [命令] [选项]"
    echo ""
    echo "可用命令:"
    echo "  init                    初始化配置目录和文件"
    echo "  edit                    编辑配置文件"
    echo "  show                    显示当前配置"
    echo "  validate                验证配置文件格式"
    echo "  copy-to-container       复制配置到运行中的容器"
    echo "  copy-from-container     从容器复制配置文件"
    echo "  reset                   重置配置为示例配置"
    echo "  help                    显示此帮助信息"
    echo ""
    echo "选项:"
    echo "  --container NAME        指定容器名称 (默认: ${CONTAINER_NAME})"
    echo "  --config-dir DIR        指定配置目录 (默认: ${CONFIG_DIR})"
    echo ""
    echo "示例:"
    echo "  $0 init"
    echo "  $0 edit"
    echo "  $0 show"
    echo "  $0 copy-to-container --container my-router"
    echo ""
}

# 解析命令行参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --container)
                CONTAINER_NAME="$2"
                shift 2
                ;;
            --config-dir)
                CONFIG_DIR="$2"
                CONFIG_FILE="${CONFIG_DIR}/config.json"
                CUSTOM_ROUTER_FILE="${CONFIG_DIR}/custom-router.js"
                shift 2
                ;;
            *)
                COMMAND="$1"
                shift
                ;;
        esac
    done
}

# 检查 Docker 是否运行
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker 未运行，请启动 Docker"
        exit 1
    fi
}

# 检查容器是否存在
check_container() {
    if ! docker ps -a --format 'table {{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        print_error "容器 '${CONTAINER_NAME}' 不存在"
        exit 1
    fi
}

# 初始化配置目录和文件
init_config() {
    print_info "初始化配置目录: ${CONFIG_DIR}"
    
    # 创建配置目录
    mkdir -p "${CONFIG_DIR}"
    
    # 复制示例配置文件
    if [[ -f "${EXAMPLE_CONFIG_FILE}" ]]; then
        cp "${EXAMPLE_CONFIG_FILE}" "${CONFIG_FILE}"
        print_success "配置文件已创建: ${CONFIG_FILE}"
    else
        print_error "示例配置文件不存在: ${EXAMPLE_CONFIG_FILE}"
        exit 1
    fi
    
    # 复制自定义路由示例文件
    if [[ -f "${EXAMPLE_CUSTOM_ROUTER_FILE}" ]]; then
        cp "${EXAMPLE_CUSTOM_ROUTER_FILE}" "${CUSTOM_ROUTER_FILE}"
        print_success "自定义路由示例文件已创建: ${CUSTOM_ROUTER_FILE}"
    fi
    
    print_info "配置文件已创建，请编辑 ${CONFIG_FILE} 来配置你的路由器"
    print_info "使用 '$0 edit' 来编辑配置文件"
}

# 编辑配置文件
edit_config() {
    if [[ ! -f "${CONFIG_FILE}" ]]; then
        print_warning "配置文件不存在，正在初始化..."
        init_config
    fi
    
    print_info "编辑配置文件: ${CONFIG_FILE}"
    
    # 尝试使用不同的编辑器
    for editor in "${EDITOR}" nano vim vi code; do
        if command -v "$editor" > /dev/null 2>&1; then
            "$editor" "${CONFIG_FILE}"
            print_success "配置文件编辑完成"
            return 0
        fi
    done
    
    print_error "未找到可用的编辑器，请手动编辑: ${CONFIG_FILE}"
    exit 1
}

# 显示当前配置
show_config() {
    if [[ ! -f "${CONFIG_FILE}" ]]; then
        print_warning "配置文件不存在: ${CONFIG_FILE}"
        print_info "使用 '$0 init' 来创建配置文件"
        return 1
    fi
    
    print_info "当前配置文件内容:"
    echo "----------------------------------------"
    cat "${CONFIG_FILE}"
    echo "----------------------------------------"
}

# 验证配置文件格式
validate_config() {
    if [[ ! -f "${CONFIG_FILE}" ]]; then
        print_error "配置文件不存在: ${CONFIG_FILE}"
        return 1
    fi
    
    print_info "验证配置文件格式..."
    
    # 检查是否为有效的 JSON
    if command -v python3 > /dev/null 2>&1; then
        if ! python3 -m json.tool "${CONFIG_FILE}" > /dev/null 2>&1; then
            print_error "配置文件不是有效的 JSON 格式"
            return 1
        fi
    elif command -v jq > /dev/null 2>&1; then
        if ! jq empty "${CONFIG_FILE}" 2>/dev/null; then
            print_error "配置文件不是有效的 JSON 格式"
            return 1
        fi
    else
        print_warning "未找到 JSON 验证工具，跳过格式验证"
        return 0
    fi
    
    print_success "配置文件格式正确"
    return 0
}

# 复制配置到运行中的容器
copy_to_container() {
    check_docker
    check_container
    
    if [[ ! -f "${CONFIG_FILE}" ]]; then
        print_error "配置文件不存在: ${CONFIG_FILE}"
        exit 1
    fi
    
    validate_config
    
    print_info "复制配置文件到容器 '${CONTAINER_NAME}'..."
    
    # 复制配置文件到容器
    docker cp "${CONFIG_FILE}" "${CONTAINER_NAME}:/root/.claude-code-router/config.json"
    
    # 如果存在自定义路由文件，也复制过去
    if [[ -f "${CUSTOM_ROUTER_FILE}" ]]; then
        docker cp "${CUSTOM_ROUTER_FILE}" "${CONTAINER_NAME}:/root/.claude-code-router/custom-router.js"
        print_info "自定义路由文件已复制"
    fi
    
    # 重启容器使配置生效
    print_info "重启容器使配置生效..."
    docker restart "${CONTAINER_NAME}"
    
    print_success "配置已更新并生效"
}

# 从容器复制配置文件
copy_from_container() {
    check_docker
    check_container
    
    print_info "从容器 '${CONTAINER_NAME}' 复制配置文件..."
    
    # 创建配置目录
    mkdir -p "${CONFIG_DIR}"
    
    # 复制配置文件
    docker cp "${CONTAINER_NAME}:/root/.claude-code-router/config.json" "${CONFIG_FILE}"
    
    # 复制自定义路由文件（如果存在）
    if docker exec "${CONTAINER_NAME}" test -f "/root/.claude-code-router/custom-router.js"; then
        docker cp "${CONTAINER_NAME}:/root/.claude-code-router/custom-router.js" "${CUSTOM_ROUTER_FILE}"
        print_info "自定义路由文件已复制"
    fi
    
    print_success "配置文件已复制到: ${CONFIG_DIR}"
}

# 重置配置为示例配置
reset_config() {
    if [[ ! -f "${EXAMPLE_CONFIG_FILE}" ]]; then
        print_error "示例配置文件不存在: ${EXAMPLE_CONFIG_FILE}"
        exit 1
    fi
    
    print_info "重置配置为示例配置..."
    
    # 备份现有配置
    if [[ -f "${CONFIG_FILE}" ]]; then
        cp "${CONFIG_FILE}" "${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
        print_info "现有配置已备份"
    fi
    
    # 复制示例配置
    cp "${EXAMPLE_CONFIG_FILE}" "${CONFIG_FILE}"
    
    print_success "配置已重置为示例配置"
    print_info "使用 '$0 edit' 来编辑配置文件"
}

# 主函数
main() {
    parse_args "$@"
    
    case "${COMMAND:-help}" in
        init)
            init_config
            ;;
        edit)
            edit_config
            ;;
        show)
            show_config
            ;;
        validate)
            validate_config
            ;;
        copy-to-container)
            copy_to_container
            ;;
        copy-from-container)
            copy_from_container
            ;;
        reset)
            reset_config
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "未知命令: ${COMMAND}"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"