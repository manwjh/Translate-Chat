#!/bin/bash
# =============================================================
# 文件名(File): fix_linux_build_issues.sh
# 版本(Version): v1.0.0
# 作者(Author): 深圳王哥 & AI
# 创建日期(Created): 2025/1/28
# 简介(Description): Linux构建问题修复脚本 - 解决常见的构建环境问题
# =============================================================

set -e

# 导入通用构建工具
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common_build_utils.sh"

# 显示帮助信息
show_help() {
    cat << EOF
Linux构建问题修复脚本 v1.0.0

用法: $0 [选项]

选项:
    -h, --help          显示此帮助信息
    -a, --all           执行所有修复
    -c, --conda         修复conda环境问题
    -p, --pip           修复pip环境问题
    -v, --venv          修复虚拟环境问题
    -d, --deps          修复系统依赖问题

示例:
    $0 -a               # 执行所有修复
    $0 -c               # 修复conda环境问题
    $0 -p               # 修复pip环境问题

EOF
}

# 修复conda环境问题
fix_conda_issues() {
    log_info "修复conda环境问题..."
    
    if [[ -n "$CONDA_DEFAULT_ENV" ]]; then
        log_warning "检测到conda环境: $CONDA_DEFAULT_ENV"
        
        # 移除与PyInstaller不兼容的包
        log_info "移除与PyInstaller不兼容的包..."
        
        # 移除pathlib包
        if conda list pathlib &> /dev/null; then
            log_info "移除conda安装的pathlib包..."
            conda remove -y pathlib || log_warning "conda移除pathlib失败"
        fi
        
        # 移除typing包
        if conda list typing &> /dev/null; then
            log_info "移除conda安装的typing包..."
            conda remove -y typing || log_warning "conda移除typing失败"
        fi
        
        # 更新conda环境
        log_info "更新conda环境..."
        conda update -y conda
        conda clean -y --all
        
        log_success "conda环境问题修复完成"
    else
        log_info "未检测到conda环境，跳过conda修复"
    fi
}

# 修复pip环境问题
fix_pip_issues() {
    log_info "修复pip环境问题..."
    
    # 升级pip到最新版本
    log_info "升级pip..."
    python3 -m pip install --upgrade pip
    
    # 清理pip缓存
    log_info "清理pip缓存..."
    pip cache purge
    
    # 移除有问题的包
    log_info "检查并移除有问题的包..."
    
    # 移除pathlib包
    if pip show pathlib &> /dev/null; then
        log_info "移除pathlib包..."
        pip uninstall -y pathlib
    fi
    
    # 移除typing包
    if pip show typing &> /dev/null; then
        log_info "移除typing包..."
        pip uninstall -y typing
    fi
    
    # 修复版本冲突
    log_info "修复版本冲突..."
    pip install --force-reinstall --upgrade setuptools wheel
    
    log_success "pip环境问题修复完成"
}

# 修复虚拟环境问题
fix_venv_issues() {
    log_info "修复虚拟环境问题..."
    
    local venv_path="$PROJECT_ROOT/venv"
    
    # 检查虚拟环境是否存在
    if [[ -d "$venv_path" ]]; then
        log_info "清理现有虚拟环境..."
        rm -rf "$venv_path"
    fi
    
    # 检查Python版本
    local python_version=$(python3 --version 2>&1)
    log_info "Python版本: $python_version"
    
    # 创建新的虚拟环境
    log_info "创建新的虚拟环境..."
    python3 -m venv "$venv_path"
    
    # 激活虚拟环境
    log_info "激活虚拟环境..."
    source "$venv_path/bin/activate"
    
    # 验证虚拟环境
    if [[ "$VIRTUAL_ENV" == "$venv_path" ]]; then
        log_success "虚拟环境创建成功: $VIRTUAL_ENV"
    else
        log_error "虚拟环境激活失败"
        return 1
    fi
    
    log_success "虚拟环境问题修复完成"
}

# 修复系统依赖问题
fix_system_deps() {
    log_info "修复系统依赖问题..."
    
    # 检测Linux发行版
    local distro=""
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        distro="$ID"
    fi
    
    log_info "检测到Linux发行版: $distro"
    
    case "$distro" in
        "ubuntu"|"debian")
            log_info "安装Ubuntu/Debian依赖..."
            sudo apt-get update
            sudo apt-get install -y python3-venv python3-pip rsync
            ;;
        "centos"|"rhel"|"fedora")
            log_info "安装CentOS/RHEL/Fedora依赖..."
            sudo yum install -y python3-venv python3-pip rsync || sudo dnf install -y python3-venv python3-pip rsync
            ;;
        "arch")
            log_info "安装Arch Linux依赖..."
            sudo pacman -S --noconfirm python-virtualenv python-pip rsync
            ;;
        *)
            log_warning "未知Linux发行版: $distro，请手动安装依赖"
            ;;
    esac
    
    log_success "系统依赖问题修复完成"
}

# 主函数
main() {
    local fix_all=false
    local fix_conda=false
    local fix_pip=false
    local fix_venv=false
    local fix_deps=false
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -a|--all)
                fix_all=true
                shift
                ;;
            -c|--conda)
                fix_conda=true
                shift
                ;;
            -p|--pip)
                fix_pip=true
                shift
                ;;
            -v|--venv)
                fix_venv=true
                shift
                ;;
            -d|--deps)
                fix_deps=true
                shift
                ;;
            *)
                log_error "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 如果没有指定选项，默认执行所有修复
    if [[ "$fix_all" == false && "$fix_conda" == false && "$fix_pip" == false && "$fix_venv" == false && "$fix_deps" == false ]]; then
        fix_all=true
    fi
    
    log_info "开始修复Linux构建问题..."
    
    if [[ "$fix_all" == true || "$fix_deps" == true ]]; then
        fix_system_deps
    fi
    
    if [[ "$fix_all" == true || "$fix_conda" == true ]]; then
        fix_conda_issues
    fi
    
    if [[ "$fix_all" == true || "$fix_pip" == true ]]; then
        fix_pip_issues
    fi
    
    if [[ "$fix_all" == true || "$fix_venv" == true ]]; then
        fix_venv_issues
    fi
    
    log_success "所有修复完成！"
    log_info "现在可以尝试重新运行构建脚本: ./scripts/local_build_linux.sh"
}

# 执行主函数
main "$@" 