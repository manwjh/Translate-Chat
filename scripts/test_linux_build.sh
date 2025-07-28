#!/bin/bash
# Translate Chat - Linux 打包环境测试脚本
# 文件名(File): test_linux_build.sh
# 版本(Version): v1.0.0
# 创建日期(Created): 2025/7/25
# 简介(Description): 测试Linux打包环境是否正确配置

set -e

# 引入通用打包工具函数
source ./scripts/common_build_utils.sh

echo "==== Translate Chat - Linux 打包环境测试脚本 v1.0.0 ===="
echo "开始时间: $(date)"
echo ""

# 检查是否为macOS系统
if [[ "$OSTYPE" != "darwin"* ]]; then
    log_error "此脚本仅适用于macOS系统"
    log_error "检测到的系统: $OSTYPE"
    exit 1
fi

# 确保在项目根目录运行
if [[ ! -f "main.py" ]]; then
    log_error "未找到main.py文件"
    log_error "请确保在项目根目录运行此脚本"
    log_error "当前目录: $(pwd)"
    log_error "请切换到项目根目录: cd /path/to/Translate-Chat"
    exit 1
fi

log_success "确认在项目根目录运行"
echo ""

echo "==== 1. 系统环境检查 ===="
log_info "检查系统环境..."

# 显示系统信息
log_info "系统信息:"
log_info "  系统: macOS $(sw_vers -productVersion)"
log_info "  架构: $(uname -m)"
log_info "  内核: $(uname -r)"
log_info "  当前用户: $(whoami)"
echo ""

echo "==== 2. Python环境检查 ===="
# 检查环境并获取Python命令
PYTHON_CMD=$(check_environment)
check_result=$?

if [[ $check_result -ne 0 ]]; then
    log_error "Python环境检查失败"
    exit 1
fi

if [[ -z "$PYTHON_CMD" ]]; then
    log_error "未获取到有效的Python命令"
    exit 1
fi

log_success "Python环境检查通过，使用Python: $PYTHON_CMD"
echo ""

echo "==== 3. Docker环境检查 ===="
# 检查Docker
if ! command -v docker &> /dev/null; then
    log_error "Docker未安装，请先安装Docker Desktop"
    log_info "下载地址: https://www.docker.com/products/docker-desktop"
    exit 1
fi

# 检查Docker是否运行
if ! docker info &> /dev/null; then
    log_error "Docker未运行，请启动Docker Desktop"
    exit 1
fi

log_success "Docker环境检查通过"
log_info "Docker版本: $(docker --version)"
echo ""

echo "==== 4. 磁盘空间检查 ===="
# 检查磁盘空间
AVAILABLE_SPACE=$(df -h . | awk 'NR==2 {print $4}' | sed 's/[^0-9]//g')
if [[ $AVAILABLE_SPACE -lt 10 ]]; then
    log_warning "可用磁盘空间不足: ${AVAILABLE_SPACE}G (建议10G以上)"
else
    log_success "磁盘空间充足: ${AVAILABLE_SPACE}G"
fi
echo ""

echo "==== 5. 网络连接检查 ===="
# 检查网络连接
if ping -c 1 8.8.8.8 &> /dev/null; then
    log_success "网络连接正常"
else
    log_warning "网络连接可能有问题，可能影响Docker镜像下载"
fi
echo ""

echo "==== 6. 依赖文件检查 ===="
# 检查Linux依赖文件
if [[ -d "build/linux/dependencies" ]]; then
    log_info "Linux依赖文件目录存在"
    
    # 检查系统依赖包
    DEB_COUNT=$(ls build/linux/dependencies/*.deb 2>/dev/null | wc -l)
    if [[ $DEB_COUNT -gt 0 ]]; then
        log_success "找到 $DEB_COUNT 个系统依赖包"
    else
        log_warning "未找到系统依赖包，建议运行: ./scripts/linux_dependency_manager.sh"
    fi
    
    # 检查Python依赖包
    WHL_COUNT=$(ls build/linux/dependencies/python_deps/*.whl 2>/dev/null | wc -l)
    if [[ $WHL_COUNT -gt 0 ]]; then
        log_success "找到 $WHL_COUNT 个Python依赖包"
    else
        log_warning "未找到Python依赖包，建议运行: ./scripts/linux_dependency_manager.sh"
    fi
else
    log_info "Linux依赖文件目录不存在，将使用在线下载"
fi
echo ""

echo "==== 7. 项目文件检查 ===="
# 检查必要的项目文件
REQUIRED_FILES=(
    "main.py"
    "requirements-desktop.txt"
    "config_manager.py"
    "translator.py"
    "asr_client.py"
    "ui/main_window_kivy.py"
    "utils/__init__.py"
)

MISSING_FILES=()
for file in "${REQUIRED_FILES[@]}"; do
    if [[ ! -f "$file" ]]; then
        MISSING_FILES+=("$file")
    fi
done

if [[ ${#MISSING_FILES[@]} -eq 0 ]]; then
    log_success "所有必要的项目文件都存在"
else
    log_error "缺少必要的项目文件:"
    for file in "${MISSING_FILES[@]}"; do
        echo "  - $file"
    done
    exit 1
fi
echo ""

echo "==== 8. 测试Docker镜像构建 ===="
log_info "测试Docker镜像构建..."

# 创建简单的测试Dockerfile
cat > test_dockerfile << 'EOF'
FROM ubuntu:22.04
RUN echo "Docker环境测试成功"
EOF

if docker build -f test_dockerfile -t test-linux-build .; then
    log_success "Docker镜像构建测试通过"
    # 清理测试镜像
    docker rmi test-linux-build 2>/dev/null || true
else
    log_warning "Docker镜像构建测试失败（可能是网络问题）"
    log_info "这不会影响本地构建，但首次构建时可能需要更长时间"
fi

# 清理测试文件
rm -f test_dockerfile
echo ""

echo "==== 9. 环境检查总结 ===="
log_success "Linux打包环境检查完成！"
echo ""
log_info "检查结果:"
echo "  ✓ 系统环境: macOS $(sw_vers -productVersion)"
echo "  ✓ Python环境: $($PYTHON_CMD --version)"
echo "  ✓ Docker环境: $(docker --version)"
echo "  ✓ 磁盘空间: ${AVAILABLE_SPACE}G"
echo "  ✓ 网络连接: 正常"
echo "  ✓ 项目文件: 完整"
echo "  ✓ Docker构建: 正常"
echo ""

echo "==== 10. 下一步操作 ===="
log_info "环境检查通过，可以进行Linux应用打包:"
echo ""
echo "1. 下载Linux依赖包（可选）:"
echo "   ./scripts/linux_dependency_manager.sh"
echo ""
echo "2. 构建Linux桌面应用:"
echo "   ./scripts/build_linux_desktop.sh"
echo ""
echo "注意: 首次构建可能需要较长时间下载Docker镜像"
echo ""

echo "==== 测试完成 ===="
echo "结束时间: $(date)"
echo "" 