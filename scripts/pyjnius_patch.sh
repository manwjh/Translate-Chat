#!/bin/bash
# Translate Chat - pyjnius 兼容性补丁脚本
# 文件名(File): pyjnius_patch.sh
# 版本(Version): v1.0.0
# 创建日期(Created): 2025/1/27
# 简介(Description): 修复pyjnius在Python 3.11下的兼容性问题

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

# 查找pyjnius源码目录
find_pyjnius_source() {
    local search_paths=(
        ".buildozer/android/platform/build-*/build/other_builds/pyjnius"
        ".buildozer/android/platform/build-*/build/python-installs/*/site-packages/pyjnius"
        "venv/lib/python*/site-packages/pyjnius"
        ".venv/lib/python*/site-packages/pyjnius"
    )
    
    for pattern in "${search_paths[@]}"; do
        for path in $pattern; do
            if [[ -d "$path" ]]; then
                echo "$path"
                return 0
            fi
        done
    done
    
    return 1
}

# 应用pyjnius补丁
apply_pyjnius_patch() {
    local pyjnius_dir="$1"
    local patch_file="$2"
    
    log_info "应用pyjnius补丁到: $pyjnius_dir"
    
    # 备份原文件
    if [[ -f "$pyjnius_dir/jnius_utils.pxi" ]]; then
        cp "$pyjnius_dir/jnius_utils.pxi" "$pyjnius_dir/jnius_utils.pxi.backup"
        log_success "已备份原文件: jnius_utils.pxi.backup"
    fi
    
    # 应用补丁
    if patch -p1 -d "$pyjnius_dir" < "$patch_file"; then
        log_success "补丁应用成功"
        return 0
    else
        log_error "补丁应用失败"
        return 1
    fi
}

# 创建pyjnius补丁文件
create_pyjnius_patch() {
    local patch_file="$1"
    
    log_info "创建pyjnius补丁文件: $patch_file"
    
    cat > "$patch_file" << 'EOF'
--- jnius_utils.pxi.orig	2025-01-27 10:00:00.000000000 +0800
+++ jnius_utils.pxi	2025-01-27 10:00:00.000000000 +0800
@@ -1,3 +1,8 @@
+# Python 3.11 compatibility patch
+# Fix for "undeclared name not builtin: long" error
+try:
+    long
+except NameError:
+    long = int
 
 # cython: language_level=3
 # cython: boundscheck=False
EOF
    
    log_success "补丁文件创建成功"
}

# 手动修复pyjnius文件
manual_fix_pyjnius() {
    local pyjnius_dir="$1"
    local utils_file="$pyjnius_dir/jnius_utils.pxi"
    
    if [[ ! -f "$utils_file" ]]; then
        log_error "未找到jnius_utils.pxi文件: $utils_file"
        return 1
    fi
    
    log_info "手动修复pyjnius文件: $utils_file"
    
    # 备份原文件
    cp "$utils_file" "$utils_file.backup"
    log_success "已备份原文件: $utils_file.backup"
    
    # 在文件开头添加兼容性代码
    local temp_file=$(mktemp)
    cat > "$temp_file" << 'EOF'
# Python 3.11 compatibility patch
# Fix for "undeclared name not builtin: long" error
try:
    long
except NameError:
    long = int

EOF
    
    # 将原文件内容追加到临时文件
    cat "$utils_file" >> "$temp_file"
    
    # 替换原文件
    mv "$temp_file" "$utils_file"
    
    log_success "手动修复完成"
}

# 检查Python版本
check_python_version() {
    local version=$(python3 --version 2>&1 | cut -d' ' -f2)
    local major=$(echo $version | cut -d'.' -f1)
    local minor=$(echo $version | cut -d'.' -f2)
    
    log_info "检测到Python版本: $version"
    
    if [[ $major -eq 3 && $minor -ge 11 ]]; then
        log_warning "检测到Python 3.11+，需要应用pyjnius兼容性补丁"
        return 0
    else
        log_info "Python版本无需补丁: $version"
        return 1
    fi
}

# 主函数
main() {
    echo "==== pyjnius 兼容性补丁脚本 ===="
    echo "开始时间: $(date)"
    echo ""
    
    # 检查Python版本
    if ! check_python_version; then
        log_info "当前Python版本无需补丁"
        exit 0
    fi
    
    # 查找pyjnius源码目录
    log_info "查找pyjnius源码目录..."
    local pyjnius_dir=$(find_pyjnius_source)
    
    if [[ -z "$pyjnius_dir" ]]; then
        log_error "未找到pyjnius源码目录"
        log_info "请先运行buildozer构建，或手动指定pyjnius目录"
        log_info "使用方法: $0 <pyjnius目录路径>"
        exit 1
    fi
    
    log_success "找到pyjnius目录: $pyjnius_dir"
    
    # 检查是否已经应用过补丁
    local utils_file="$pyjnius_dir/jnius_utils.pxi"
    if [[ -f "$utils_file" ]] && grep -q "long = int" "$utils_file"; then
        log_success "补丁已应用，无需重复操作"
        exit 0
    fi
    
    # 创建补丁文件
    local patch_file="/tmp/pyjnius_python311.patch"
    create_pyjnius_patch "$patch_file"
    
    # 尝试应用补丁
    if apply_pyjnius_patch "$pyjnius_dir" "$patch_file"; then
        log_success "补丁应用成功"
    else
        log_warning "补丁应用失败，尝试手动修复..."
        if manual_fix_pyjnius "$pyjnius_dir"; then
            log_success "手动修复成功"
        else
            log_error "手动修复失败"
            exit 1
        fi
    fi
    
    # 清理临时文件
    rm -f "$patch_file"
    
    echo ""
    log_success "pyjnius兼容性补丁应用完成"
    log_info "现在可以重新运行buildozer构建"
    echo ""
    echo "==== 补丁完成 ===="
    echo "结束时间: $(date)"
}

# 如果提供了参数，使用指定的pyjnius目录
if [[ $# -eq 1 ]]; then
    if [[ -d "$1" ]]; then
        log_info "使用指定的pyjnius目录: $1"
        pyjnius_dir="$1"
        main
    else
        log_error "指定的目录不存在: $1"
        exit 1
    fi
else
    main
fi 