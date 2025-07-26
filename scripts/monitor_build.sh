#!/bin/bash
# Translate Chat - 构建监控脚本
# 文件名(File): monitor_build.sh
# 版本(Version): v1.0.0
# 作者(Author): 深圳王哥 & AI
# 创建日期(Created): 2025/1/27
# 简介(Description): 监控buildozer构建进度

echo "==== Buildozer 构建监控 ===="
echo "监控时间: $(date)"
echo ""

# 检查构建目录
build_dir="scripts/.buildozer"
if [ ! -d "$build_dir" ]; then
    echo "❌ 构建目录不存在: $build_dir"
    exit 1
fi

echo "✅ 构建目录存在: $build_dir"

# 检查构建状态
echo ""
echo "==== 构建状态检查 ===="

# 检查python-for-android
if [ -d "$build_dir/android/platform/python-for-android" ]; then
    echo "✅ python-for-android 已下载"
else
    echo "❌ python-for-android 未找到"
fi

# 检查构建目录
if [ -d "$build_dir/android/platform/build-arm64-v8a_armeabi-v7a" ]; then
    echo "✅ 构建目录已创建"
    
    # 检查构建进度
    build_path="$build_dir/android/platform/build-arm64-v8a_armeabi-v7a"
    
    echo ""
    echo "==== 构建进度 ===="
    
    # 检查已编译的库
    if [ -d "$build_path/build/other_builds" ]; then
        echo "📦 已编译的库:"
        ls -la "$build_path/build/other_builds/" 2>/dev/null | grep -E "(hostpython3|libffi|openssl|python3)" || echo "  暂无"
    fi
    
    # 检查SDL2相关库
    if [ -d "$build_path/build/bootstrap_builds/sdl2/jni" ]; then
        echo ""
        echo "🎮 SDL2库状态:"
        ls -la "$build_path/build/bootstrap_builds/sdl2/jni/" 2>/dev/null | grep -E "(SDL|SDL2)" || echo "  暂无"
    fi
    
    # 检查最终输出
    if [ -d "$build_path/dists" ]; then
        echo ""
        echo "📱 输出目录:"
        ls -la "$build_path/dists/" 2>/dev/null || echo "  暂无"
    fi
else
    echo "❌ 构建目录未创建"
fi

echo ""
echo "==== 系统资源监控 ===="

# 检查CPU和内存使用
echo "💻 CPU使用率:"
top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1

echo "🧠 内存使用:"
free -h | grep "Mem:" | awk '{print "已用: " $3 "/" $2 " (" $3/$2*100 "%)"}'

echo "💾 磁盘使用:"
df -h . | tail -1 | awk '{print "已用: " $3 "/" $2 " (" $5 ")"}'

echo ""
echo "==== 网络连接状态 ===="

# 检查网络连接
if ping -c 1 github.com >/dev/null 2>&1; then
    echo "✅ GitHub 连接正常"
else
    echo "❌ GitHub 连接异常"
fi

if ping -c 1 pypi.org >/dev/null 2>&1; then
    echo "✅ PyPI 连接正常"
else
    echo "❌ PyPI 连接异常"
fi

echo ""
echo "==== 构建日志监控 ===="

# 检查最近的构建日志
log_file="$build_dir/buildozer.log"
if [ -f "$log_file" ]; then
    echo "📋 最近的构建日志 (最后10行):"
    tail -10 "$log_file" 2>/dev/null || echo "  无法读取日志文件"
else
    echo "ℹ️  构建日志文件不存在"
fi

echo ""
echo "==== 监控完成 ===="
echo "提示: 构建过程可能需要30分钟到2小时，请耐心等待"
echo "如果构建卡住超过30分钟，可以尝试重启构建" 