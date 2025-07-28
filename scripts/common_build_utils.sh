#!/bin/bash
# Translate Chat - 通用构建工具脚本
# 文件名(File): common_build_utils.sh
# 版本(Version): v2.0.0
# 创建日期(Created): 2025/7/25
# 简介(Description): 通用构建工具函数，移除Android支持，专注桌面端

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
    local version
    
    if ! command -v "$python_cmd" &> /dev/null; then
        log_error "Python命令不存在: $python_cmd"
        return 1
    fi
    
    version=$("$python_cmd" --version 2>&1 | cut -d' ' -f2)
    local major=$(echo "$version" | cut -d'.' -f1)
    local minor=$(echo "$version" | cut -d'.' -f2)
    
    log_info "检测到Python版本: $version"
    
    if [[ $major -eq 3 ]] && [[ $minor -ge 9 ]] && [[ $minor -le 11 ]]; then
        log_success "Python版本兼容: $version"
        return 0
    else
        log_error "Python版本不兼容: $version (需要3.9-3.11)"
        return 1
    fi
}

# 安装兼容的Python版本
install_compatible_python() {
    local system=$(detect_system)
    local target_version="3.10"
    
    if [[ "$system" == "ubuntu" ]]; then
        # Ubuntu: 使用apt安装Python 3.10
        log_info "在Ubuntu上安装Python $target_version..." >&2
        
        if ! command -v python3.10 &> /dev/null; then
            log_info "安装Python 3.10..." >&2
            if ! sudo apt update && sudo apt install -y python3.10 python3.10-venv python3.10-dev; then
                log_error "安装Python 3.10失败" >&2
                return 1
            fi
        fi
        
        # 检查安装结果
        if command -v python3.10 &> /dev/null; then
            log_success "Python 3.10安装成功" >&2
            printf "%s" "python3.10"
            return 0
        else
            log_error "Python 3.10安装失败" >&2
            return 1
        fi
        
    elif [[ "$system" == "macos" ]]; then
        # macOS: 使用Homebrew安装Python 3.10
        log_info "在macOS上安装Python $target_version..." >&2
        
        if ! command -v brew &> /dev/null; then
            log_error "Homebrew未安装，请先安装Homebrew" >&2
            return 1
        fi
        
        if ! brew list --versions python@3.10 >/dev/null; then
            log_info "安装Python 3.10..." >&2
            if ! brew install python@3.10; then
                log_error "安装Python 3.10失败" >&2
                return 1
            fi
        fi
        
        # 检查安装结果
        if [[ -f "/opt/homebrew/bin/python3.10" ]]; then
            log_success "Python 3.10安装成功" >&2
            printf "%s" "/opt/homebrew/bin/python3.10"
            return 0
        elif [[ -f "/usr/local/bin/python3.10" ]]; then
            log_success "Python 3.10安装成功" >&2
            printf "%s" "/usr/local/bin/python3.10"
            return 0
        else
            log_error "Python 3.10安装失败" >&2
            return 1
        fi
        
    else
        log_error "不支持的系统类型: $system" >&2
        return 1
    fi
}

# 设置pip镜像
setup_pip_mirror() {
    log_info "配置pip镜像源..."
    
    # 创建pip配置目录
    mkdir -p ~/.pip
    
    # 配置清华源
    cat > ~/.pip/pip.conf << EOF
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
trusted-host = pypi.tuna.tsinghua.edu.cn
timeout = 120
EOF
    
    log_success "pip镜像源配置完成"
}

# 创建虚拟环境
create_venv() {
    local python_cmd="$1"
    local venv_path="$2"
    
    log_info "创建Python虚拟环境: $venv_path"
    
    if [[ -d "$venv_path" ]]; then
        log_warning "虚拟环境已存在: $venv_path"
        return 0
    fi
    
    if "$python_cmd" -m venv "$venv_path"; then
        log_success "虚拟环境创建成功: $venv_path"
        return 0
    else
        log_error "虚拟环境创建失败: $venv_path"
        return 1
    fi
}

# 安装Python依赖
install_python_deps() {
    local venv_path="$1"
    
    log_info "安装Python依赖..."
    
    # 激活虚拟环境
    source "$venv_path/bin/activate"
    
    # 升级pip
    pip install --upgrade pip setuptools wheel
    
    # 安装依赖
    if pip install -r requirements-desktop.txt; then
        log_success "Python依赖安装完成"
        return 0
    else
        log_error "Python依赖安装失败"
        return 1
    fi
}

# 检查Docker环境
check_docker_environment() {
    log_info "检查Docker环境..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker未安装"
        return 1
    fi
    
    if ! docker info &> /dev/null; then
        log_error "Docker未运行"
        return 1
    fi
    
    log_success "Docker环境检查通过"
    return 0
}

# 检查磁盘空间
check_disk_space() {
    local required_space=10  # GB
    local available_space
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        available_space=$(df -g . | awk 'NR==2 {print $4}')
    else
        available_space=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
    fi
    
    log_info "可用磁盘空间: ${available_space}GB"
    
    if [[ $available_space -lt $required_space ]]; then
        log_error "磁盘空间不足: 需要${required_space}GB，可用${available_space}GB"
        return 1
    fi
    
    log_success "磁盘空间检查通过"
    return 0
}

# 检查网络连接
check_network_connection() {
    log_info "检查网络连接..."
    
    if ping -c 1 8.8.8.8 &> /dev/null; then
        log_success "网络连接正常"
        return 0
    else
        log_warning "网络连接异常，可能影响依赖下载"
        return 0  # 不强制要求网络连接
    fi
}

# 环境检查主函数
check_environment() {
    local system=$(detect_system)
    log_info "检测到系统: $system" >&2
    
    # 检查Python
    local python_cmd="python3"
    log_info "开始检查Python环境..." >&2
    
    if ! check_python_version "$python_cmd" >&2; then
        log_warning "当前Python版本不兼容，尝试自动安装合适的版本..." >&2
        local new_python_cmd
        new_python_cmd=$(install_compatible_python)
        local install_result=$?
        
        log_info "安装结果: $install_result, 新Python命令: '$new_python_cmd'" >&2
        
        if [[ $install_result -eq 0 && -n "$new_python_cmd" ]]; then
            log_success "使用新安装的Python: $new_python_cmd" >&2
            # 重新检查版本
            if check_python_version "$new_python_cmd" >&2; then
                log_success "Python环境检查通过" >&2
                # 返回新安装的Python命令
                printf "%s" "$new_python_cmd"
                return 0
            else
                log_error "Python环境检查失败" >&2
                return 1
            fi
        else
            log_error "无法安装合适的Python版本" >&2
            log_info "请手动安装Python 3.9-3.11版本后重试" >&2
            return 1
        fi
    else
        log_success "Python环境检查通过" >&2
        printf "%s" "$python_cmd"
        return 0
    fi
}

# 错误处理函数
handle_error() {
    local exit_code=$?
    log_error "脚本执行失败，退出码: $exit_code"
    exit $exit_code
}

# 设置错误处理
trap handle_error ERR

# 清理函数
cleanup() {
    log_info "清理临时文件..."
    # 可以在这里添加清理逻辑
}

# 设置退出时清理
trap cleanup EXIT 