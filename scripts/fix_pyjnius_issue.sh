#!/bin/bash
# pyjnius 编译问题修复脚本 / pyjnius Compilation Issue Fix Script
# 文件名(File): fix_pyjnius_issue.sh
# 版本(Version): v1.0.0
# 作者(Author): AI Assistant
# 创建日期(Created): 2025/1/27
# 简介(Description): 修复pyjnius在Android打包时的编译问题

set -e

echo "==== pyjnius 编译问题修复脚本 ===="
echo "==== pyjnius Compilation Issue Fix Script ===="
echo ""

# 检查是否在虚拟环境中
if [ -z "$VIRTUAL_ENV" ]; then
    echo "错误: 请在虚拟环境中运行此脚本"
    echo "请先运行: source venv/bin/activate"
    exit 1
fi

echo "当前Python版本: $(python --version)"
echo "当前Cython版本: $(cython --version 2>/dev/null || echo '未安装')"
echo ""

# 1. 降级Cython到兼容版本
echo "1. 降级Cython到兼容版本..."
echo "正在卸载当前Cython版本..."
pip uninstall -y cython || true

echo "正在安装兼容的Cython版本..."
pip install "cython<3.0"

echo "新的Cython版本: $(cython --version)"
echo ""

# 2. 安装兼容的pyjnius版本
echo "2. 安装兼容的pyjnius版本..."
echo "正在卸载当前pyjnius版本..."
pip uninstall -y pyjnius || true

echo "正在安装兼容的pyjnius版本..."
pip install "pyjnius<1.5"

echo ""

# 3. 更新buildozer.spec中的requirements
echo "3. 更新buildozer.spec配置..."
if [ -f buildozer.spec ]; then
    # 备份原文件
    cp buildozer.spec buildozer.spec.backup
    echo "已备份 buildozer.spec 为 buildozer.spec.backup"
    
    # 更新requirements行，添加版本限制
    sed -i 's/requirements = python3,kivy>=2.3.0,kivymd==1.1.1,plyer>=2.1.0,ffpyplayer>=4.5.0,websocket-client,aiohttp/requirements = python3,kivy>=2.3.0,kivymd==1.1.1,plyer>=2.1.0,ffpyplayer>=4.5.0,websocket-client,aiohttp,cython<3.0,pyjnius<1.5/' buildozer.spec
    
    echo "已更新 buildozer.spec 中的 requirements"
else
    echo "警告: 未找到 buildozer.spec 文件"
fi

echo ""

# 4. 清理之前的构建缓存
echo "4. 清理之前的构建缓存..."
if [ -d ".buildozer" ]; then
    echo "正在清理 .buildozer 目录..."
    rm -rf .buildozer
    echo "✓ 已清理 .buildozer 目录"
fi

echo ""

# 5. 验证修复
echo "5. 验证修复结果..."
echo "当前安装的包版本:"
pip list | grep -E "(cython|pyjnius)" || echo "未找到相关包"

echo ""
echo "==== 修复完成 ===="
echo "修复内容:"
echo "1. ✓ 降级Cython到 <3.0 版本"
echo "2. ✓ 安装pyjnius <1.5 版本"
echo "3. ✓ 更新buildozer.spec配置"
echo "4. ✓ 清理构建缓存"
echo ""
echo "现在可以重新运行打包命令:"
echo "  buildozer -v android debug"
echo ""
echo "如果仍有问题，请尝试:"
echo "1. 完全清理环境: rm -rf venv && python3 -m venv venv"
echo "2. 重新安装依赖: pip install -r requirements-android.txt"
echo "3. 运行此修复脚本"
echo "" 