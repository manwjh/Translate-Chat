#!/bin/bash
# Translate Chat - 交叉编译环境测试脚本
# 文件名(File): test_cross_build_env.sh
# 版本(Version): v1.0.0
# 创建日期(Created): 2025/1/27
# 简介(Description): 测试交叉编译环境配置

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "==== Translate Chat - 交叉编译环境测试 ===="
echo "测试时间: $(date)"
echo ""

# 测试结果统计
PASSED=0
FAILED=0

# 测试函数
test_check() {
    local test_name="$1"
    local test_cmd="$2"
    local expected_result="$3"
    
    log_info "测试: $test_name"
    
    if eval "$test_cmd" >/dev/null 2>&1; then
        if [[ "$expected_result" == "success" ]]; then
            log_success "✓ $test_name 通过"
            ((PASSED++))
        else
            log_error "✗ $test_name 失败 (期望失败但成功了)"
            ((FAILED++))
        fi
    else
        if [[ "$expected_result" == "success" ]]; then
            log_error "✗ $test_name 失败"
            ((FAILED++))
        else
            log_success "✓ $test_name 通过 (期望失败且确实失败了)"
            ((PASSED++))
        fi
    fi
    echo ""
}

# 1. 系统检查
echo "==== 1. 系统环境检查 ===="

test_check "操作系统类型" "[[ \"$OSTYPE\" == \"linux-gnu\"* ]]" "success"
test_check "系统架构" "uname -m | grep -q 'x86_64'" "success"
test_check "内核版本" "uname -r | grep -q '.'" "success"

# 2. 基础工具检查
echo "==== 2. 基础工具检查 ===="

test_check "Python3" "command -v python3" "success"
test_check "pip3" "command -v pip3" "success"
test_check "git" "command -v git" "success"
test_check "tar" "command -v tar" "success"
test_check "gzip" "command -v gzip" "success"

# 3. Docker检查
echo "==== 3. Docker环境检查 ===="

test_check "Docker命令" "command -v docker" "success"
test_check "Docker服务" "docker info >/dev/null 2>&1" "success"
test_check "Docker权限" "docker run --rm hello-world >/dev/null 2>&1" "success"

# 4. Python环境检查
echo "==== 4. Python环境检查 ===="

PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2)
PYTHON_MAJOR=$(echo "$PYTHON_VERSION" | cut -d'.' -f1)
PYTHON_MINOR=$(echo "$PYTHON_VERSION" | cut -d'.' -f2)

log_info "Python版本: $PYTHON_VERSION"

test_check "Python版本兼容性" "[[ $PYTHON_MAJOR -eq 3 ]] && [[ $PYTHON_MINOR -ge 9 ]] && [[ $PYTHON_MINOR -le 11 ]]" "success"
test_check "venv模块" "python3 -m venv --help >/dev/null 2>&1" "success"
test_check "pip升级" "pip3 install --upgrade pip >/dev/null 2>&1" "success"

# 5. 构建工具检查
echo "==== 5. 构建工具检查 ===="

test_check "gcc" "command -v gcc" "success"
test_check "g++" "command -v g++" "success"
test_check "make" "command -v make" "success"
test_check "cmake" "command -v cmake" "success"
test_check "pkg-config" "command -v pkg-config" "success"

# 6. 系统库检查
echo "==== 6. 系统库检查 ===="

test_check "ALSA开发库" "pkg-config --exists alsa" "success"
test_check "PortAudio开发库" "pkg-config --exists portaudio-2.0" "success"
test_check "OpenSSL开发库" "pkg-config --exists openssl" "success"
test_check "FFI开发库" "pkg-config --exists libffi" "success"

# 7. 项目文件检查
echo "==== 7. 项目文件检查 ===="

test_check "main.py存在" "[[ -f main.py ]]" "success"
test_check "requirements-desktop.txt存在" "[[ -f requirements-desktop.txt ]]" "success"
test_check "assets目录存在" "[[ -d assets ]]" "success"
test_check "ui目录存在" "[[ -d ui ]]" "success"
test_check "utils目录存在" "[[ -d utils ]]" "success"

# 8. Docker多架构支持检查
echo "==== 8. Docker多架构支持检查 ===="

test_check "Docker buildx" "docker buildx version >/dev/null 2>&1" "success"
test_check "ARM64平台支持" "docker buildx inspect --bootstrap >/dev/null 2>&1" "success"

# 9. 网络连接检查
echo "==== 9. 网络连接检查 ===="

test_check "PyPI连接" "curl -s --connect-timeout 5 https://pypi.org/ >/dev/null" "success"
test_check "Docker Hub连接" "curl -s --connect-timeout 5 https://registry-1.docker.io/ >/dev/null" "success"

# 10. 磁盘空间检查
echo "==== 10. 磁盘空间检查 ===="

AVAILABLE_SPACE=$(df . | awk 'NR==2 {print $4}')
REQUIRED_SPACE=5000000  # 5GB in KB

test_check "磁盘空间充足" "[[ $AVAILABLE_SPACE -gt $REQUIRED_SPACE ]]" "success"

log_info "可用磁盘空间: $((AVAILABLE_SPACE / 1024 / 1024)) GB"

# 11. 内存检查
echo "==== 11. 内存检查 ===="

TOTAL_MEM=$(free | awk 'NR==2{print $2}')
REQUIRED_MEM=4000000  # 4GB in KB

test_check "内存充足" "[[ $TOTAL_MEM -gt $REQUIRED_MEM ]]" "success"

log_info "总内存: $((TOTAL_MEM / 1024 / 1024)) GB"

# 测试总结
echo "==== 测试总结 ===="
log_info "总测试数: $((PASSED + FAILED))"
log_info "通过: $PASSED"
log_info "失败: $FAILED"

if [[ $FAILED -eq 0 ]]; then
    log_success "所有测试通过！环境配置正确，可以开始构建。"
    echo ""
    log_info "建议执行以下命令开始构建："
    echo "  ./scripts/quick_build.sh"
    exit 0
else
    log_error "有 $FAILED 个测试失败，请检查环境配置。"
    echo ""
    log_info "常见解决方案："
    echo "  1. 安装缺失的依赖包"
    echo "  2. 配置Docker权限"
    echo "  3. 检查网络连接"
    echo "  4. 确保磁盘空间充足"
    exit 1
fi 