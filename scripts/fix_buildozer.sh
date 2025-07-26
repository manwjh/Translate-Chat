#!/bin/bash
# Translate Chat - Buildozer 快速修复脚本
# 文件名(File): fix_buildozer.sh
# 版本(Version): v1.0.0
# 作者(Author): 深圳王哥 & AI
# 创建日期(Created): 2025/1/27
# 简介(Description): 快速修复buildozer配置问题

echo "==== Buildozer 快速修复 ===="

# 检查是否在项目根目录
if [ ! -f "buildozer.spec" ]; then
    echo "错误: 请在项目根目录运行此脚本"
    exit 1
fi

echo "1. 修复已弃用的配置项..."

# 修复 android.arch -> android.archs
if grep -q "android\.arch = " buildozer.spec; then
    sed -i 's/android\.arch = /android.archs = /g' buildozer.spec
    echo "✓ 已修复 android.arch 配置"
fi

# 移除已弃用的 android.sdk
if grep -q "android\.sdk = " buildozer.spec; then
    sed -i '/android\.sdk = /d' buildozer.spec
    echo "✓ 已移除 android.sdk 配置"
fi

echo "2. 清理构建缓存..."
if [ -d ".buildozer" ]; then
    rm -rf .buildozer
    echo "✓ 已清理 .buildozer 目录"
fi

echo "3. 设置环境变量..."
export JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64"
export PATH="$JAVA_HOME/bin:$PATH"

echo "✓ 修复完成！现在可以重新运行构建脚本" 