#!/bin/bash
# Translate Chat - 环境诊断脚本
# 文件名(File): debug_environment.sh
# 版本(Version): v1.0.0
# 创建日期(Created): 2025/1/27
# 简介(Description): 诊断构建环境问题

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "==== Translate Chat - 环境诊断脚本 ===="
echo "开始时间: $(date)"
echo ""

# 系统信息
log_info "=== 系统信息 ==="
log_info "操作系统: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
log_info "架构: $(uname -m)"
log_info "内核版本: $(uname -r)"
log_info "当前用户: $(whoami)"
log_info "当前目录: $(pwd)"
echo ""

# Python环境检查
log_info "=== Python环境检查 ==="
for cmd in python3 python3.10 python3.11 python3.9; do
    if command -v "$cmd" &> /dev/null; then
        local version_output
        version_output=$("$cmd" --version 2>&1)
        log_success "$cmd: $version_output"
    else
        log_warning "$cmd: 未找到"
    fi
done
echo ""

# Java环境检查
log_info "=== Java环境检查 ==="
if command -v java &> /dev/null; then
    local java_version
    java_version=$(java -version 2>&1 | head -n 1)
    log_success "Java: $java_version"
    
    if [[ -n "$JAVA_HOME" ]]; then
        log_success "JAVA_HOME: $JAVA_HOME"
    else
        log_warning "JAVA_HOME: 未设置"
    fi
else
    log_error "Java: 未找到"
fi
echo ""

# 权限检查
log_info "=== 权限检查 ==="
if [[ $EUID -eq 0 ]]; then
    log_warning "当前以root用户运行，建议使用普通用户"
else
    log_success "当前以普通用户运行"
fi

# 检查sudo权限
if sudo -n true 2>/dev/null; then
    log_success "sudo权限: 可用"
else
    log_warning "sudo权限: 需要密码"
fi
echo ""

# 网络连接检查
log_info "=== 网络连接检查 ==="
if ping -c 1 8.8.8.8 &> /dev/null; then
    log_success "网络连接: 正常"
else
    log_error "网络连接: 异常"
fi

if curl -s --connect-timeout 5 https://pypi.org &> /dev/null; then
    log_success "PyPI访问: 正常"
else
    log_warning "PyPI访问: 异常"
fi
echo ""

# 磁盘空间检查
log_info "=== 磁盘空间检查 ==="
local available_space
available_space=$(df -h . | awk 'NR==2 {print $4}')
log_info "可用空间: $available_space"

local total_space
total_space=$(df -h . | awk 'NR==2 {print $2}')
log_info "总空间: $total_space"
echo ""

# 依赖包检查
log_info "=== 系统依赖检查 ==="
local deps=("git" "cmake" "pkg-config" "build-essential")
for dep in "${deps[@]}"; do
    if command -v "$dep" &> /dev/null; then
        log_success "$dep: 已安装"
    else
        log_warning "$dep: 未安装"
    fi
done
echo ""

# 测试通用函数
log_info "=== 测试通用函数 ==="
if [[ -f "./scripts/common_build_utils.sh" ]]; then
    log_success "common_build_utils.sh: 存在"
    
    # 测试系统检测
    if source ./scripts/common_build_utils.sh 2>/dev/null; then
        log_success "通用函数: 加载成功"
        
        # 测试系统检测函数
        local system
        system=$(detect_system)
        log_info "检测到的系统: $system"
    else
        log_error "通用函数: 加载失败"
    fi
else
    log_error "common_build_utils.sh: 不存在"
fi
echo ""

# 总结
log_info "=== 诊断总结 ==="
log_info "如果发现问题，请根据上述信息进行修复"
log_info "常见问题："
log_info "1. Python版本不兼容 - 脚本会自动安装"
log_info "2. Java未安装 - 脚本会自动安装"
log_info "3. 权限不足 - 确保有sudo权限"
log_info "4. 网络问题 - 检查网络连接"
log_info "5. 磁盘空间不足 - 清理磁盘空间"

echo ""
echo "==== 诊断完成 ===="
echo "结束时间: $(date)" 