#!/bin/bash
# Translate Chat - 通用构建工具脚本
# 文件名(File): common_build_utils.sh
# 版本(Version): v1.0.0
# 创建日期(Created): 2025/1/27
# 简介(Description): 通用构建工具函数，支持macOS和Ubuntu环境

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

# 检查系统类型
detect_system() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ -f /etc/os-release ]]; then
        if grep -q "Ubuntu" /etc/os-release; then
            echo "ubuntu"
        else
            echo "linux"
        fi
    else
        echo "unknown"
    fi
}

# 检查Python版本
check_python_version() {
    local python_cmd="$1"
    
    # 检查命令是否存在
    if ! command -v "$python_cmd" &> /dev/null; then
        log_error "Python命令不存在: $python_cmd"
        return 1
    fi
    
    # 获取版本信息，处理不同输出格式
    local version_output
    version_output=$("$python_cmd" --version 2>&1)
    
    # 调试信息
    log_info "Python版本输出: '$version_output'"
    
    # 解析版本号，支持多种格式
    local version=""
    if [[ "$version_output" =~ Python[[:space:]]+([0-9]+\.[0-9]+\.[0-9]+) ]]; then
        version="${BASH_REMATCH[1]}"
    elif [[ "$version_output" =~ ([0-9]+\.[0-9]+\.[0-9]+) ]]; then
        version="${BASH_REMATCH[1]}"
    else
        log_error "无法解析Python版本: $version_output"
        return 1
    fi
    
    local major=$(echo "$version" | cut -d'.' -f1)
    local minor=$(echo "$version" | cut -d'.' -f2)
    
    log_info "检测到Python版本: $version (major=$major, minor=$minor)"
    
    if [[ $major -eq 3 && $minor -ge 9 && $minor -le 11 ]]; then
        log_success "Python版本兼容: $version"
        return 0
    else
        log_warning "Python版本不兼容: $version (需要Python 3.9-3.11)"
        return 1
    fi
}

# 自动安装合适的Python版本
install_compatible_python() {
    local system=$(detect_system)
    local target_version="3.10"
    
    log_info "尝试自动安装Python $target_version..."
    
    if [[ "$system" == "ubuntu" ]]; then
        # Ubuntu: 使用deadsnakes PPA安装Python 3.10
        log_info "在Ubuntu上安装Python $target_version..."
        
        # 添加deadsnakes PPA
        if ! grep -q "deadsnakes" /etc/apt/sources.list.d/* 2>/dev/null; then
            log_info "添加deadsnakes PPA..."
            if ! sudo add-apt-repository ppa:deadsnakes/ppa -y; then
                log_error "添加deadsnakes PPA失败"
                return 1
            fi
            if ! sudo apt update; then
                log_error "更新包列表失败"
                return 1
            fi
        fi
        
        # 安装Python 3.10
        if ! command -v python3.10 &> /dev/null; then
            log_info "安装Python 3.10..."
            if ! sudo apt install -y python3.10 python3.10-venv python3.10-dev python3.10-pip; then
                log_error "安装Python 3.10失败"
                return 1
            fi
        fi
        
        # 检查安装结果
        if command -v python3.10 &> /dev/null; then
            log_success "Python 3.10安装成功"
            echo "python3.10"
            return 0
        else
            log_error "Python 3.10安装失败"
            return 1
        fi
        
    elif [[ "$system" == "macos" ]]; then
        # macOS: 使用Homebrew安装Python 3.10
        log_info "在macOS上安装Python $target_version..."
        
        if ! command -v brew &> /dev/null; then
            log_error "Homebrew未安装，请先安装Homebrew"
            return 1
        fi
        
        if ! brew list --versions python@3.10 >/dev/null; then
            log_info "安装Python 3.10..."
            if ! brew install python@3.10; then
                log_error "安装Python 3.10失败"
                return 1
            fi
        fi
        
        # 检查安装结果
        if [[ -f "/opt/homebrew/bin/python3.10" ]]; then
            log_success "Python 3.10安装成功"
            echo "/opt/homebrew/bin/python3.10"
            return 0
        elif [[ -f "/usr/local/bin/python3.10" ]]; then
            log_success "Python 3.10安装成功"
            echo "/usr/local/bin/python3.10"
            return 0
        else
            log_error "Python 3.10安装失败"
            return 1
        fi
        
    else
        log_error "不支持的系统类型: $system"
        return 1
    fi
}

# 检查Java版本
check_java_version() {
    if ! command -v java &> /dev/null; then
        log_error "Java未安装"
        return 1
    fi
    
    local version=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2)
    local major=$(echo $version | cut -d'.' -f1)
    
    log_info "检测到Java版本: $version"
    
    if [[ $major -ge 11 ]]; then
        log_success "Java版本兼容: $version"
        return 0
    else
        log_warning "Java版本较低: $version (推荐Java 11+)"
        return 0
    fi
}

# 设置Java环境变量
setup_java_env() {
    local system=$(detect_system)
    
    if [[ "$system" == "macos" ]]; then
        # macOS: 优先使用JDK 17
        if [[ -d "/opt/homebrew/opt/openjdk@17" ]]; then
            export JAVA_HOME="/opt/homebrew/opt/openjdk@17"
            export PATH="$JAVA_HOME/bin:$PATH"
            log_success "设置JAVA_HOME为: $JAVA_HOME"
        elif [[ -d "/usr/local/opt/openjdk@17" ]]; then
            export JAVA_HOME="/usr/local/opt/openjdk@17"
            export PATH="$JAVA_HOME/bin:$PATH"
            log_success "设置JAVA_HOME为: $JAVA_HOME"
        else
            log_warning "未找到JDK 17，尝试使用系统Java"
        fi
    elif [[ "$system" == "ubuntu" ]]; then
        # Ubuntu: 优先使用JDK 17，回退到JDK 11
        if [[ -d "/usr/lib/jvm/java-17-openjdk-amd64" ]]; then
            export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
            export PATH="$JAVA_HOME/bin:$PATH"
            log_success "设置JAVA_HOME为: $JAVA_HOME"
        elif [[ -d "/usr/lib/jvm/java-11-openjdk-amd64" ]]; then
            export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
            export PATH="$JAVA_HOME/bin:$PATH"
            log_success "设置JAVA_HOME为: $JAVA_HOME"
        elif [[ -d "/usr/lib/jvm/java-8-openjdk-amd64" ]]; then
            export JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64"
            export PATH="$JAVA_HOME/bin:$PATH"
            log_warning "使用JDK 8: $JAVA_HOME (推荐升级到JDK 11+)"
        else
            log_error "未找到合适的Java环境"
            return 1
        fi
    fi
}

# 配置pip镜像
setup_pip_mirror() {
    log_info "配置pip国内镜像..."
    mkdir -p ~/.pip
    cat > ~/.pip/pip.conf <<EOF
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
trusted-host = pypi.tuna.tsinghua.edu.cn
timeout = 120
EOF
    log_success "pip镜像已配置为清华源"
}

# 检查并准备本地依赖包
verify_and_prepare_all_dependencies() {
    log_info "检查本地依赖包..."
    
    # 检查SDL2本地文件
    local sdl2_paths=(
        "/tmp/SDL2-2.28.5.tar"
        "/tmp/SDL2_mixer-2.6.3.tar"
        "/tmp/SDL2_image-2.8.0.tar"
        "/tmp/SDL2_ttf-2.20.2.tar"
    )
    
    for path in "${sdl2_paths[@]}"; do
        if [[ -f "$path" ]]; then
            log_success "找到本地文件: $(basename $path)"
            case "$path" in
                *SDL2-*.tar)
                    export SDL2_LOCAL_PATH="$path"
                    ;;
                *SDL2_mixer*.tar)
                    export SDL2_MIXER_LOCAL_PATH="$path"
                    ;;
                *SDL2_image*.tar)
                    export SDL2_IMAGE_LOCAL_PATH="$path"
                    ;;
                *SDL2_ttf*.tar)
                    export SDL2_TTF_LOCAL_PATH="$path"
                    ;;
            esac
        else
            log_warning "未找到本地文件: $(basename $path)"
        fi
    done
    
    # 显示环境变量
    if [[ -n "$SDL2_LOCAL_PATH" ]]; then
        log_info "SDL2本地文件配置:"
        [[ -n "$SDL2_LOCAL_PATH" ]] && echo "  - SDL2_LOCAL_PATH: $SDL2_LOCAL_PATH"
        [[ -n "$SDL2_MIXER_LOCAL_PATH" ]] && echo "  - SDL2_MIXER_LOCAL_PATH: $SDL2_MIXER_LOCAL_PATH"
        [[ -n "$SDL2_IMAGE_LOCAL_PATH" ]] && echo "  - SDL2_IMAGE_LOCAL_PATH: $SDL2_IMAGE_LOCAL_PATH"
        [[ -n "$SDL2_TTF_LOCAL_PATH" ]] && echo "  - SDL2_TTF_LOCAL_PATH: $SDL2_TTF_LOCAL_PATH"
    fi
}

# 创建Python虚拟环境
create_venv() {
    local python_cmd="$1"
    local venv_dir="$2"
    
    if [[ ! -d "$venv_dir" ]]; then
        log_info "创建Python虚拟环境: $venv_dir"
        $python_cmd -m venv "$venv_dir"
        if [[ $? -eq 0 ]]; then
            log_success "虚拟环境创建成功"
        else
            log_error "虚拟环境创建失败"
            return 1
        fi
    else
        log_info "虚拟环境已存在: $venv_dir"
    fi
}

# 安装Python依赖
install_python_deps() {
    local venv_dir="$1"
    
    log_info "激活虚拟环境并安装依赖..."
    source "$venv_dir/bin/activate"
    
    # 升级pip
    pip install --upgrade pip setuptools wheel
    
    # 安装基础工具
    pip install cython==0.29.36
    
    # 安装buildozer
    pip install buildozer==1.5.0
    
    log_success "Python依赖安装完成"
}

# 清理构建缓存
clean_build_cache() {
    log_info "清理构建缓存..."
    
    if [[ -d ".buildozer" ]]; then
        if command -v buildozer &> /dev/null; then
            if buildozer android clean; then
                log_success "buildozer清理成功"
            else
                log_warning "buildozer清理失败，尝试手动清理..."
                rm -rf .buildozer
                log_success "已手动清理.buildozer目录"
            fi
        else
            rm -rf .buildozer
            log_success "已手动清理.buildozer目录"
        fi
    else
        log_info "无需清理，.buildozer目录不存在"
    fi
}

# 检查构建结果
check_build_result() {
    if [[ -d "bin" ]]; then
        local apk_count=$(ls bin/*.apk 2>/dev/null | wc -l)
        if [[ $apk_count -gt 0 ]]; then
            log_success "构建成功！找到 $apk_count 个APK文件:"
            ls -lh bin/*.apk
            return 0
        else
            log_error "构建失败：未找到APK文件"
            return 1
        fi
    else
        log_error "构建失败：未找到bin目录"
        return 1
    fi
}

# 环境检查主函数
check_environment() {
    local system=$(detect_system)
    log_info "检测到系统: $system"
    
    # 检查Python
    local python_cmd="python3"
    log_info "开始检查Python环境..."
    
    if ! check_python_version "$python_cmd"; then
        log_warning "当前Python版本不兼容，尝试自动安装合适的版本..."
        local new_python_cmd
        new_python_cmd=$(install_compatible_python)
        local install_result=$?
        
        log_info "安装结果: $install_result, 新Python命令: '$new_python_cmd'"
        
        if [[ $install_result -eq 0 && -n "$new_python_cmd" ]]; then
            log_success "使用新安装的Python: $new_python_cmd"
            # 重新检查版本
            if check_python_version "$new_python_cmd"; then
                log_success "Python环境检查通过"
                # 返回新安装的Python命令
                echo "$new_python_cmd"
                return 0
            else
                log_error "Python环境检查失败"
                return 1
            fi
        else
            log_error "无法安装合适的Python版本"
            log_info "请手动安装Python 3.9-3.11版本后重试"
            return 1
        fi
    else
        log_success "Python环境检查通过"
        echo "$python_cmd"
        return 0
    fi
}

# 错误处理函数
handle_error() {
    local exit_code=$?
    local line_number=${BASH_LINENO[0]}
    local script_name=${BASH_SOURCE[1]}
    
    log_error "构建过程中发生错误"
    log_error "退出码: $exit_code"
    log_error "错误位置: $script_name:$line_number"
    
    # 显示最近的命令
    log_info "最近的命令:"
    if [[ -n "$BASH_COMMAND" ]]; then
        log_info "  $BASH_COMMAND"
    fi
    
    # 显示环境信息
    log_info "环境信息:"
    log_info "  系统: $(detect_system)"
    log_info "  当前目录: $(pwd)"
    log_info "  Python: $(which python3 2>/dev/null || echo '未找到')"
    log_info "  Java: $(which java 2>/dev/null || echo '未找到')"
    
    log_info "请检查日志并修复问题后重试"
    exit $exit_code
}

# 设置错误处理
trap handle_error ERR

# 导出函数供其他脚本使用
export -f log_info log_success log_warning log_error
export -f detect_system check_python_version check_java_version
export -f setup_java_env setup_pip_mirror verify_and_prepare_all_dependencies
export -f create_venv install_python_deps clean_build_cache check_build_result
export -f check_environment handle_error install_compatible_python 