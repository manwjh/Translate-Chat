#!/bin/bash
# =============================================================
# 文件名(File): linux_deploy.sh
# 版本(Version): v1.0.0
# 作者(Author): 深圳王哥 & AI
# 创建日期(Created): 2025/07/29
# 简介(Description): Linux平台完整部署脚本 - 自动安装依赖、配置环境、运行应用
# =============================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${PURPLE}[STEP]${NC} $1"; }
log_debug() { echo -e "${CYAN}[DEBUG]${NC} $1"; }

# 显示帮助信息
show_help() {
    cat << EOF
Linux平台完整部署脚本 v1.0.0

用法: $0 [选项] [可执行文件路径]

选项:
    -h, --help              显示此帮助信息
    -v, --verbose           详细输出
    -i, --install-only      仅安装依赖，不运行应用
    -r, --run-only          仅运行应用，跳过依赖安装
    -c, --check-only        仅检查环境和依赖
    -d, --desktop           创建桌面快捷方式
    -b, --background        后台运行应用
    --user <用户名>         指定运行用户（默认当前用户）
    --install-dir <目录>    指定安装目录（默认当前目录）

参数:
    可执行文件路径           translate-chat可执行文件的完整路径
                            （如果未指定，将在当前目录查找）

示例:
    $0                                    # 自动查找并部署
    $0 ./translate-chat                   # 部署指定文件
    $0 /path/to/translate-chat -d         # 部署并创建桌面快捷方式
    $0 -i                                 # 仅安装依赖
    $0 -r                                 # 仅运行应用
    $0 -c                                 # 仅检查环境

功能特性:
    ✅ 自动检测Linux发行版
    ✅ 自动安装系统依赖（PortAudio等）
    ✅ 自动配置音频设备权限
    ✅ 自动检查依赖库
    ✅ 自动创建桌面快捷方式
    ✅ 支持后台运行
    ✅ 完整的故障排除
    ✅ 详细的日志输出

注意: 此脚本需要sudo权限来安装系统依赖包
EOF
}

# 全局变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERBOSE=false
INSTALL_ONLY=false
RUN_ONLY=false
CHECK_ONLY=false
CREATE_DESKTOP=false
BACKGROUND_RUN=false
TARGET_USER=""
INSTALL_DIR=""
EXECUTABLE_PATH=""
APP_NAME="translate-chat"

# 检测Linux发行版
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "$ID"
    elif [[ -f /etc/redhat-release ]]; then
        echo "rhel"
    elif [[ -f /etc/debian_version ]]; then
        echo "debian"
    else
        echo "unknown"
    fi
}

# 检测系统架构
detect_arch() {
    uname -m
}

# 检查是否为ARM64架构
check_arm64() {
    local arch=$(detect_arch)
    if [[ "$arch" == "aarch64" || "$arch" == "arm64" ]]; then
        return 0
    else
        return 1
    fi
}

# 查找可执行文件
find_executable() {
    local search_paths=(
        "./$APP_NAME"
        "./dist/arm64/$APP_NAME"
        "./dist/x86_64/$APP_NAME"
        "/home/$USER/$APP_NAME"
        "/opt/$APP_NAME"
        "/usr/local/bin/$APP_NAME"
    )
    
    for path in "${search_paths[@]}"; do
        if [[ -f "$path" && -x "$path" ]]; then
            echo "$path"
            return 0
        fi
    done
    
    return 1
}

# 验证可执行文件
validate_executable() {
    local file_path="$1"
    
    log_step "验证可执行文件: $file_path"
    
    # 检查文件是否存在
    if [[ ! -f "$file_path" ]]; then
        log_error "文件不存在: $file_path"
        return 1
    fi
    
    # 检查文件类型
    local file_type=$(file "$file_path" 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        log_error "无法读取文件类型"
        return 1
    fi
    
    log_debug "文件类型: $file_type"
    
    # 检查是否为ELF可执行文件
    if ! echo "$file_type" | grep -q "ELF.*executable"; then
        log_error "不是有效的ELF可执行文件"
        return 1
    fi
    
    # 检查架构
    if check_arm64; then
        if ! echo "$file_type" | grep -q "ARM aarch64\|ARM64"; then
            log_warning "当前系统是ARM64，但可执行文件可能不是ARM64架构"
        fi
    else
        if ! echo "$file_type" | grep -q "x86-64\|x86_64"; then
            log_warning "当前系统是x86_64，但可执行文件可能不是x86_64架构"
        fi
    fi
    
    # 检查执行权限
    if [[ ! -x "$file_path" ]]; then
        log_info "添加执行权限"
        chmod +x "$file_path"
    fi
    
    log_success "可执行文件验证通过"
    return 0
}

# 安装Ubuntu/Debian依赖
install_ubuntu_deps() {
    log_step "安装Ubuntu/Debian系统依赖"
    
    # 更新包列表
    log_info "更新包列表..."
    sudo apt-get update
    
    # 安装基础依赖
    log_info "安装基础依赖..."
    sudo apt-get install -y \
        portaudio19-dev \
        python3-dev \
        build-essential \
        libasound2-dev \
        libpulse-dev \
        libjack-jackd2-dev \
        python3 \
        python3-pip \
        python3-venv \
        curl \
        wget \
        file
    
    # 安装音频相关库
    log_info "安装音频库..."
    sudo apt-get install -y \
        libportaudio2 \
        libasound2 \
        libpulse0 \
        libjack-jackd2-0
    
    log_success "Ubuntu/Debian依赖安装完成"
}

# 安装CentOS/RHEL依赖
install_centos_deps() {
    log_step "安装CentOS/RHEL系统依赖"
    
    # 安装EPEL仓库
    log_info "安装EPEL仓库..."
    sudo yum install -y epel-release
    
    # 安装基础依赖
    log_info "安装基础依赖..."
    sudo yum install -y \
        portaudio-devel \
        python3-devel \
        gcc \
        gcc-c++ \
        make \
        alsa-lib-devel \
        pulseaudio-libs-devel \
        jack-audio-connection-kit-devel \
        python3 \
        python3-pip \
        curl \
        wget \
        file
    
    log_success "CentOS/RHEL依赖安装完成"
}

# 安装Fedora依赖
install_fedora_deps() {
    log_step "安装Fedora系统依赖"
    
    # 安装基础依赖
    log_info "安装基础依赖..."
    sudo dnf install -y \
        portaudio-devel \
        python3-devel \
        gcc \
        gcc-c++ \
        make \
        alsa-lib-devel \
        pulseaudio-libs-devel \
        jack-audio-connection-kit-devel \
        python3 \
        python3-pip \
        curl \
        wget \
        file
    
    log_success "Fedora依赖安装完成"
}

# 安装系统依赖
install_system_deps() {
    local distro=$(detect_distro)
    
    log_step "检测到Linux发行版: $distro"
    
    case "$distro" in
        "ubuntu"|"debian"|"raspbian"|"linuxmint")
            install_ubuntu_deps
            ;;
        "centos"|"rhel"|"rocky"|"almalinux")
            install_centos_deps
            ;;
        "fedora")
            install_fedora_deps
            ;;
        *)
            log_error "不支持的Linux发行版: $distro"
            log_info "请手动安装以下依赖:"
            log_info "  - portaudio19-dev (或 portaudio-devel)"
            log_info "  - python3-dev (或 python3-devel)"
            log_info "  - build-essential (或 gcc, make)"
            log_info "  - libasound2-dev (或 alsa-lib-devel)"
            return 1
            ;;
    esac
}

# 配置音频设备权限
setup_audio_permissions() {
    log_step "配置音频设备权限"
    
    local current_user=${TARGET_USER:-$USER}
    
    # 检查用户是否在audio组
    if ! groups "$current_user" | grep -q audio; then
        log_info "将用户 $current_user 添加到audio组..."
        sudo usermod -a -G audio "$current_user"
        log_warning "需要重新登录才能生效，或者运行: newgrp audio"
    else
        log_info "用户 $current_user 已在audio组中"
    fi
    
    # 检查音频设备
    if [[ -d /dev/snd ]]; then
        log_info "检查音频设备..."
        ls -la /dev/snd/ | head -10
    else
        log_warning "未找到音频设备目录 /dev/snd"
    fi
    
    # 检查PulseAudio
    if command -v pulseaudio >/dev/null 2>&1; then
        log_info "PulseAudio已安装"
    else
        log_warning "PulseAudio未安装，可能影响音频功能"
    fi
    
    log_success "音频设备权限配置完成"
}

# 检查依赖库
check_dependencies() {
    log_step "检查依赖库"
    
    if [[ -z "$EXECUTABLE_PATH" ]]; then
        log_error "可执行文件路径未设置"
        return 1
    fi
    
    # 检查ldd命令
    if ! command -v ldd >/dev/null 2>&1; then
        log_error "ldd命令不可用，无法检查依赖库"
        return 1
    fi
    
    # 检查依赖库
    log_info "检查可执行文件依赖库..."
    local missing_libs=$(ldd "$EXECUTABLE_PATH" 2>/dev/null | grep "not found" || true)
    
    if [[ -n "$missing_libs" ]]; then
        log_warning "发现缺失的依赖库:"
        echo "$missing_libs" | while read -r line; do
            log_warning "  $line"
        done
        
        log_info "尝试安装缺失的库..."
        
        # 尝试安装常见的缺失库
        local distro=$(detect_distro)
        case "$distro" in
            "ubuntu"|"debian"|"raspbian"|"linuxmint")
                sudo apt-get install -y libportaudio2 libasound2 libpulse0
                ;;
            "centos"|"rhel"|"rocky"|"almalinux")
                sudo yum install -y portaudio alsa-lib pulseaudio-libs
                ;;
            "fedora")
                sudo dnf install -y portaudio alsa-lib pulseaudio-libs
                ;;
        esac
        
        # 重新检查
        log_info "重新检查依赖库..."
        missing_libs=$(ldd "$EXECUTABLE_PATH" 2>/dev/null | grep "not found" || true)
        if [[ -n "$missing_libs" ]]; then
            log_error "仍有缺失的依赖库，请手动安装"
            return 1
        fi
    fi
    
    log_success "所有依赖库检查通过"
    return 0
}

# 创建桌面快捷方式
create_desktop_shortcut() {
    log_step "创建桌面快捷方式"
    
    local current_user=${TARGET_USER:-$USER}
    local desktop_dir=""
    
    # 查找桌面目录
    for dir in "/home/$current_user/Desktop" "/home/$current_user/桌面" "/home/$current_user/.local/share/applications"; do
        if [[ -d "$dir" ]]; then
            desktop_dir="$dir"
            break
        fi
    done
    
    if [[ -z "$desktop_dir" ]]; then
        log_warning "未找到桌面目录，跳过创建快捷方式"
        return 1
    fi
    
    # 创建桌面文件
    local desktop_file="$desktop_dir/translate-chat.desktop"
    log_info "创建桌面文件: $desktop_file"
    
    cat > "$desktop_file" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Translate Chat
Name[zh_CN]=语音翻译助手
Comment=Real-time speech recognition and translation
Comment[zh_CN]=实时语音识别翻译应用
Exec=$EXECUTABLE_PATH
Icon=applications-multimedia
Terminal=false
Categories=AudioVideo;Audio;Network;
Keywords=speech;translation;voice;audio;
StartupWMClass=translate-chat
EOF
    
    # 设置权限
    chmod +x "$desktop_file"
    chown "$current_user:$current_user" "$desktop_file"
    
    log_success "桌面快捷方式创建完成: $desktop_file"
    return 0
}

# 运行应用
run_application() {
    log_step "运行应用"
    
    if [[ -z "$EXECUTABLE_PATH" ]]; then
        log_error "可执行文件路径未设置"
        return 1
    fi
    
    # 检查是否在后台运行
    if [[ "$BACKGROUND_RUN" == true ]]; then
        log_info "后台运行应用..."
        nohup "$EXECUTABLE_PATH" > app.log 2>&1 &
        local pid=$!
        log_success "应用已在后台启动，PID: $pid"
        log_info "查看日志: tail -f app.log"
        log_info "停止应用: kill $pid"
    else
        log_info "前台运行应用..."
        log_info "按 Ctrl+C 停止应用"
        "$EXECUTABLE_PATH"
    fi
}

# 环境检查
check_environment() {
    log_step "检查运行环境"
    
    # 检查系统信息
    log_info "系统信息:"
    log_info "  发行版: $(detect_distro)"
    log_info "  架构: $(detect_arch)"
    log_info "  内核: $(uname -r)"
    log_info "  用户: $USER"
    
    # 检查必要命令
    local required_commands=("file" "ldd" "chmod" "chown")
    for cmd in "${required_commands[@]}"; do
        if command -v "$cmd" >/dev/null 2>&1; then
            log_debug "  ✅ $cmd"
        else
            log_warning "  ❌ $cmd 不可用"
        fi
    done
    
    # 检查音频设备
    log_info "音频设备检查:"
    if [[ -d /dev/snd ]]; then
        log_info "  ✅ 音频设备目录存在"
        ls -la /dev/snd/ | head -5
    else
        log_warning "  ❌ 音频设备目录不存在"
    fi
    
    # 检查网络连接
    log_info "网络连接检查:"
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        log_info "  ✅ 网络连接正常"
    else
        log_warning "  ❌ 网络连接异常"
    fi
    
    log_success "环境检查完成"
}

# 故障排除
troubleshoot() {
    log_step "故障排除指南"
    
    cat << EOF
==========================================
故障排除指南
==========================================

1. 权限问题:
   - 确保文件有执行权限: chmod +x $EXECUTABLE_PATH
   - 确保用户在audio组: groups $USER
   - 重新登录或运行: newgrp audio

2. 依赖库问题:
   - 检查缺失库: ldd $EXECUTABLE_PATH
   - 安装缺失库: sudo apt-get install <库名>

3. 音频设备问题:
   - 检查音频设备: ls /dev/snd/
   - 检查PulseAudio: pulseaudio --check
   - 重启音频服务: sudo systemctl restart pulseaudio

4. 网络连接问题:
   - 检查网络: ping 8.8.8.8
   - 检查防火墙: sudo ufw status

5. 应用配置问题:
   - 首次运行会启动配置界面
   - 需要配置ASR和翻译API密钥
   - 配置文件保存在加密存储中

6. 日志查看:
   - 前台运行: 直接查看控制台输出
   - 后台运行: tail -f app.log

7. 停止应用:
   - 前台运行: Ctrl+C
   - 后台运行: kill <PID>

==========================================
EOF
}

# 主函数
main() {
    log_info "=========================================="
    log_info "Linux平台完整部署脚本 v1.0.0"
    log_info "=========================================="
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -i|--install-only)
                INSTALL_ONLY=true
                shift
                ;;
            -r|--run-only)
                RUN_ONLY=true
                shift
                ;;
            -c|--check-only)
                CHECK_ONLY=true
                shift
                ;;
            -d|--desktop)
                CREATE_DESKTOP=true
                shift
                ;;
            -b|--background)
                BACKGROUND_RUN=true
                shift
                ;;
            --user)
                TARGET_USER="$2"
                shift 2
                ;;
            --install-dir)
                INSTALL_DIR="$2"
                shift 2
                ;;
            -*)
                log_error "未知选项: $1"
                show_help
                exit 1
                ;;
            *)
                EXECUTABLE_PATH="$1"
                shift
                ;;
        esac
    done
    
    # 设置详细输出
    if [[ "$VERBOSE" == true ]]; then
        set -x
    fi
    
    # 检查root权限（仅安装依赖时需要）
    if [[ "$INSTALL_ONLY" == true || "$CHECK_ONLY" == false ]]; then
        if [[ $EUID -eq 0 ]]; then
            log_warning "不建议以root用户运行此脚本"
            read -p "是否继续? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
    fi
    
    # 环境检查
    check_environment
    
    # 仅检查模式
    if [[ "$CHECK_ONLY" == true ]]; then
        log_success "环境检查完成"
        exit 0
    fi
    
    # 查找可执行文件
    if [[ -z "$EXECUTABLE_PATH" ]]; then
        log_info "自动查找可执行文件..."
        EXECUTABLE_PATH=$(find_executable)
        if [[ -z "$EXECUTABLE_PATH" ]]; then
            log_error "未找到可执行文件 $APP_NAME"
            log_info "请指定可执行文件的完整路径"
            show_help
            exit 1
        fi
        log_info "找到可执行文件: $EXECUTABLE_PATH"
    fi
    
    # 验证可执行文件
    if ! validate_executable "$EXECUTABLE_PATH"; then
        log_error "可执行文件验证失败"
        exit 1
    fi
    
    # 仅运行模式
    if [[ "$RUN_ONLY" == true ]]; then
        if ! check_dependencies; then
            log_error "依赖检查失败"
            exit 1
        fi
        run_application
        exit 0
    fi
    
    # 安装系统依赖
    if [[ "$INSTALL_ONLY" == true || "$RUN_ONLY" == false ]]; then
        if ! install_system_deps; then
            log_error "系统依赖安装失败"
            exit 1
        fi
        
        # 配置音频权限
        setup_audio_permissions
        
        # 检查依赖库
        if ! check_dependencies; then
            log_error "依赖库检查失败"
            exit 1
        fi
    fi
    
    # 仅安装模式
    if [[ "$INSTALL_ONLY" == true ]]; then
        log_success "依赖安装完成"
        exit 0
    fi
    
    # 创建桌面快捷方式
    if [[ "$CREATE_DESKTOP" == true ]]; then
        create_desktop_shortcut
    fi
    
    # 运行应用
    run_application
    
    # 显示故障排除信息
    troubleshoot
    
    log_success "=========================================="
    log_success "部署完成！"
    log_success "=========================================="
}

# 运行主函数
main "$@" 