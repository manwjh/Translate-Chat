#!/bin/bash

# =============================================================================
# 自动代码推送脚本 / Auto Code Push Script
# 创建时间: 2024-07-28 / Created: 2024-07-28
# 功能: 自动将本地代码推送到远程仓库 / Function: Auto push local code to remote repository
# =============================================================================

set -e  # 遇到错误时退出 / Exit on error

# 颜色定义 / Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数 / Logging functions
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

# 显示帮助信息 / Show help information
show_help() {
    echo "用法 / Usage: $0 [选项 / options]"
    echo ""
    echo "选项 / Options:"
    echo "  -h, --help              显示此帮助信息 / Show this help message"
    echo "  -m, --message <msg>     自定义提交信息 / Custom commit message"
    echo "  -f, --force             强制推送 / Force push"
    echo "  -a, --all               添加所有文件到暂存区 / Add all files to staging"
    echo "  -c, --check-only        仅检查状态，不推送 / Only check status, don't push"
    echo "  -v, --verbose           详细输出 / Verbose output"
    echo ""
    echo "示例 / Examples:"
    echo "  $0                      # 使用默认设置推送 / Push with default settings"
    echo "  $0 -m '修复bug'          # 使用自定义提交信息 / Use custom commit message"
    echo "  $0 -a -m '添加新功能'    # 添加所有文件并推送 / Add all files and push"
    echo "  $0 -c                   # 仅检查状态 / Only check status"
}

# 检查Git是否安装 / Check if Git is installed
check_git() {
    if ! command -v git &> /dev/null; then
        log_error "Git未安装，请先安装Git / Git is not installed, please install Git first"
        exit 1
    fi
}

# 检查是否在Git仓库中 / Check if in a Git repository
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "当前目录不是Git仓库 / Current directory is not a Git repository"
        exit 1
    fi
}

# 检查远程仓库配置 / Check remote repository configuration
check_remote() {
    if ! git remote get-url origin > /dev/null 2>&1; then
        log_error "未配置远程仓库origin / Remote repository 'origin' not configured"
        exit 1
    fi
}

# 获取当前分支 / Get current branch
get_current_branch() {
    git branch --show-current
}

# 检查是否有未提交的更改 / Check for uncommitted changes
check_changes() {
    if git diff-index --quiet HEAD --; then
        log_info "工作区干净，没有未提交的更改 / Working directory is clean, no uncommitted changes"
        return 0
    else
        log_warning "发现未提交的更改 / Found uncommitted changes"
        return 1
    fi
}

# 显示更改状态 / Show change status
show_status() {
    log_info "当前Git状态 / Current Git status:"
    echo "----------------------------------------"
    git status --short
    echo "----------------------------------------"
    
    if [ "$VERBOSE" = true ]; then
        log_info "详细更改信息 / Detailed change information:"
        git diff --stat
    fi
}

# 添加文件到暂存区 / Add files to staging area
add_files() {
    if [ "$ADD_ALL" = true ]; then
        log_info "添加所有文件到暂存区 / Adding all files to staging area"
        git add .
    else
        log_info "添加修改的文件到暂存区 / Adding modified files to staging area"
        git add -u
    fi
}

# 创建提交 / Create commit
create_commit() {
    local commit_msg="$1"
    
    if [ -z "$commit_msg" ]; then
        # 生成默认提交信息 / Generate default commit message
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        local branch=$(get_current_branch)
        commit_msg="自动提交 - $timestamp [$branch] / Auto commit - $timestamp [$branch]"
    fi
    
    log_info "创建提交: $commit_msg / Creating commit: $commit_msg"
    git commit -m "$commit_msg"
}

# 推送到远程仓库 / Push to remote repository
push_to_remote() {
    local current_branch=$(get_current_branch)
    local force_flag=""
    
    if [ "$FORCE_PUSH" = true ]; then
        force_flag="--force"
        log_warning "使用强制推送 / Using force push"
    fi
    
    log_info "推送到远程仓库 / Pushing to remote repository"
    log_info "分支: $current_branch / Branch: $current_branch"
    log_info "远程: origin / Remote: origin"
    
    if git push $force_flag origin "$current_branch"; then
        log_success "推送成功 / Push successful"
        return 0
    else
        log_error "推送失败 / Push failed"
        return 1
    fi
}

# 拉取远程更新 / Pull remote updates
pull_remote() {
    log_info "拉取远程更新 / Pulling remote updates"
    if git pull origin $(get_current_branch); then
        log_success "拉取成功 / Pull successful"
        return 0
    else
        log_warning "拉取失败，可能存在冲突 / Pull failed, conflicts may exist"
        return 1
    fi
}

# 主函数 / Main function
main() {
    local commit_message=""
    local check_only=false
    local add_all=false
    local force_push=false
    local verbose=false
    
    # 解析命令行参数 / Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -m|--message)
                commit_message="$2"
                shift 2
                ;;
            -f|--force)
                force_push=true
                shift
                ;;
            -a|--all)
                add_all=true
                shift
                ;;
            -c|--check-only)
                check_only=true
                shift
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            *)
                log_error "未知参数: $1 / Unknown parameter: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 设置全局变量 / Set global variables
    export VERBOSE=$verbose
    export ADD_ALL=$add_all
    export FORCE_PUSH=$force_push
    
    log_info "开始自动推送流程 / Starting auto push process"
    log_info "================================================"
    
    # 基本检查 / Basic checks
    check_git
    check_git_repo
    check_remote
    
    # 显示当前状态 / Show current status
    local current_branch=$(get_current_branch)
    log_info "当前分支: $current_branch / Current branch: $current_branch"
    log_info "远程仓库: $(git remote get-url origin) / Remote repository: $(git remote get-url origin)"
    
    show_status
    
    # 如果只是检查，则退出 / If only checking, exit
    if [ "$check_only" = true ]; then
        log_info "仅检查模式，退出 / Check-only mode, exiting"
        exit 0
    fi
    
    # 检查是否有更改 / Check for changes
    if check_changes; then
        log_info "没有需要提交的更改 / No changes to commit"
        exit 0
    fi
    
    # 拉取远程更新 / Pull remote updates
    if ! pull_remote; then
        log_warning "拉取远程更新失败，但继续执行 / Failed to pull remote updates, but continuing"
    fi
    
    # 添加文件 / Add files
    add_files
    
    # 再次检查是否有更改 / Check for changes again
    if check_changes; then
        log_info "添加文件后仍无更改，退出 / Still no changes after adding files, exiting"
        exit 0
    fi
    
    # 创建提交 / Create commit
    create_commit "$commit_message"
    
    # 推送到远程 / Push to remote
    if push_to_remote; then
        log_success "自动推送完成 / Auto push completed successfully"
        log_info "================================================"
        exit 0
    else
        log_error "自动推送失败 / Auto push failed"
        log_info "================================================"
        exit 1
    fi
}

# 错误处理 / Error handling
trap 'log_error "脚本执行中断 / Script execution interrupted"; exit 1' INT TERM

# 执行主函数 / Execute main function
main "$@" 