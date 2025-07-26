#!/bin/bash
# Translate Chat - Buildozer 诊断脚本
# 文件名(File): diagnose_buildozer.sh
# 版本(Version): v1.0.0
# 作者(Author): 深圳王哥 & AI
# 创建日期(Created): 2025/1/27
# 简介(Description): 快速诊断buildozer配置和环境问题

echo "==== Translate Chat - Buildozer 诊断脚本 ===="
echo "诊断时间: $(date)"
echo ""

# 检查是否在项目根目录
if [ ! -f "buildozer.spec" ]; then
    echo "❌ 错误: 请在项目根目录运行此脚本"
    exit 1
fi

echo "==== 1. 检查buildozer.spec配置 ===="

# 检查已弃用的配置
echo "检查已弃用的配置项..."

if grep -q "android\.arch = " buildozer.spec; then
    echo "❌ 发现已弃用的配置: android.arch"
    echo "   建议: 使用 android.archs 替代"
else
    echo "✅ android.arch 配置正确"
fi

if grep -q "android\.sdk = " buildozer.spec; then
    echo "❌ 发现已弃用的配置: android.sdk"
    echo "   建议: 移除此配置项"
else
    echo "✅ android.sdk 配置正确"
fi

# 检查必要的配置
echo ""
echo "检查必要的配置项..."

if grep -q "android\.archs = " buildozer.spec; then
    echo "✅ android.archs 已配置"
    archs=$(grep "android\.archs = " buildozer.spec | cut -d'=' -f2 | tr -d ' ')
    echo "   当前架构: $archs"
else
    echo "❌ 缺少 android.archs 配置"
fi

if grep -q "android\.api = " buildozer.spec; then
    echo "✅ android.api 已配置"
else
    echo "❌ 缺少 android.api 配置"
fi

if grep -q "android\.minapi = " buildozer.spec; then
    echo "✅ android.minapi 已配置"
else
    echo "❌ 缺少 android.minapi 配置"
fi

echo ""
echo "==== 2. 检查系统环境 ===="

# 检查Python
if command -v python3 &> /dev/null; then
    echo "✅ Python3 已安装: $(python3 --version)"
else
    echo "❌ Python3 未安装"
fi

# 检查Java
if command -v java &> /dev/null; then
    echo "✅ Java 已安装: $(java -version 2>&1 | head -1)"
else
    echo "❌ Java 未安装"
fi

# 检查buildozer
if command -v buildozer &> /dev/null; then
    echo "✅ Buildozer 已安装: $(buildozer --version)"
else
    echo "❌ Buildozer 未安装"
fi

# 检查git
if command -v git &> /dev/null; then
    echo "✅ Git 已安装: $(git --version)"
else
    echo "❌ Git 未安装"
fi

echo ""
echo "==== 3. 检查虚拟环境 ===="

if [ -d "venv" ]; then
    echo "✅ 虚拟环境存在"
    if [ -f "venv/bin/activate" ]; then
        echo "✅ 虚拟环境激活脚本存在"
    else
        echo "❌ 虚拟环境激活脚本缺失"
    fi
else
    echo "❌ 虚拟环境不存在"
fi

echo ""
echo "==== 4. 检查构建目录 ===="

if [ -d ".buildozer" ]; then
    echo "✅ .buildozer 目录存在"
    
    if [ -d ".buildozer/android/platform/python-for-android" ]; then
        echo "✅ python-for-android 目录存在"
    else
        echo "❌ python-for-android 目录缺失"
    fi
    
    if [ -d ".buildozer/android/platform/build-arm64-v8a" ]; then
        echo "✅ build-arm64-v8a 目录存在"
    else
        echo "❌ build-arm64-v8a 目录缺失"
    fi
else
    echo "ℹ️  .buildozer 目录不存在（首次构建）"
fi

echo ""
echo "==== 5. 检查SDL2本地文件 ===="

sdl2_files=(
    "/tmp/SDL2-2.28.5.tar"
    "/tmp/SDL2_image-2.8.0.tar"
    "/tmp/SDL_image-release-2.0.tar"
    "/tmp/SDL2_mixer-2.6.3.tar"
    "/tmp/SDL2_ttf-2.20.2.tar"
    "/tmp/SDL_ttf-release-2.0.15.tar"
)

sdl2_found=false
for file in "${sdl2_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ SDL2文件存在: $file"
        sdl2_found=true
    fi
done

if [ "$sdl2_found" = false ]; then
    echo "ℹ️  未找到SDL2本地文件，将使用网络下载"
fi

echo ""
echo "==== 6. 权限检查 ===="

# 检查当前目录权限
if [ -w "." ]; then
    echo "✅ 当前目录可写"
else
    echo "❌ 当前目录不可写"
fi

# 检查.buildozer目录权限
if [ -d ".buildozer" ]; then
    if [ -w ".buildozer" ]; then
        echo "✅ .buildozer目录可写"
    else
        echo "❌ .buildozer目录不可写"
    fi
fi

echo ""
echo "==== 7. 诊断总结 ===="

echo "如果发现问题，请运行修复脚本:"
echo "  ./scripts/fix_buildozer.sh"
echo ""
echo "或者手动修复以下问题:"
echo "1. 更新已弃用的配置项"
echo "2. 安装缺失的系统依赖"
echo "3. 创建虚拟环境"
echo "4. 清理构建缓存"
echo ""

echo "==== 诊断完成 ====" 