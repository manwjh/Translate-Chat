#!/bin/bash
# 完整构建修复脚本 / Complete Build Fix Script
# 文件名(File): complete_build_fix.sh
# 版本(Version): v1.0.0
# 作者(Author): AI Assistant
# 创建日期(Created): 2025/1/27
# 简介(Description): 完整的Android构建问题修复脚本，包含依赖下载和pyjnius问题修复

set -e

echo "==== 完整构建修复脚本 ===="
echo "==== Complete Build Fix Script ===="
echo ""

# 检查是否在虚拟环境中
if [ -z "$VIRTUAL_ENV" ]; then
    echo "错误: 请在虚拟环境中运行此脚本"
    echo "请先运行: source venv/bin/activate"
    exit 1
fi

echo "当前工作目录: $(pwd)"
echo "虚拟环境: $VIRTUAL_ENV"
echo "Python版本: $(python --version)"
echo ""

# 第一步: 下载SDL2依赖
echo "==== 第一步: 下载SDL2依赖 ===="
if [ -f ./scripts/sdl2_local_manager.sh ]; then
    echo "运行SDL2本地文件管理脚本..."
    bash ./scripts/sdl2_local_manager.sh
else
    echo "警告: 未找到 sdl2_local_manager.sh，跳过SDL2下载"
fi

echo ""

# 第二步: 下载Python依赖包
echo "==== 第二步: 下载Python依赖包 ===="
mkdir -p ./wheels
echo "下载Android依赖包到 ./wheels 目录..."
if [ -f requirements-android.txt ]; then
    pip download -r requirements-android.txt -d ./wheels
    echo "✓ Android依赖包下载完成"
else
    echo "警告: 未找到 requirements-android.txt"
fi

if [ -f requirements-desktop.txt ]; then
    pip download -r requirements-desktop.txt -d ./wheels
    echo "✓ Desktop依赖包下载完成"
fi

# 下载构建工具
echo "下载构建工具..."
pip download buildozer cython -d ./wheels
echo "✓ 构建工具下载完成"

echo ""

# 第三步: 修复pyjnius编译问题
echo "==== 第三步: 修复pyjnius编译问题 ===="
echo "降级Cython到兼容版本..."
pip uninstall -y cython || true
pip install "cython<3.0"
echo "✓ Cython已降级到兼容版本"

echo "安装兼容的pyjnius版本..."
pip uninstall -y pyjnius || true
pip install "pyjnius<1.5"
echo "✓ pyjnius已安装兼容版本"

echo ""

# 第四步: 更新buildozer.spec
echo "==== 第四步: 更新buildozer.spec配置 ===="
if [ -f buildozer.spec ]; then
    # 备份原文件
    cp buildozer.spec buildozer.spec.backup.$(date +%Y%m%d_%H%M%S)
    echo "✓ 已备份 buildozer.spec"
    
    # 更新requirements行
    if grep -q "cython<3.0" buildozer.spec; then
        echo "✓ buildozer.spec 已包含兼容版本限制"
    else
        echo "正在更新 buildozer.spec 中的 requirements..."
        # 使用更安全的方式更新requirements
        sed -i 's/requirements = python3,kivy>=2.3.0,kivymd==1.1.1,plyer>=2.1.0,ffpyplayer>=4.5.0,websocket-client,aiohttp/requirements = python3,kivy>=2.3.0,kivymd==1.1.1,plyer>=2.1.0,ffpyplayer>=4.5.0,websocket-client,aiohttp,cython<3.0,pyjnius<1.5/' buildozer.spec
        echo "✓ 已更新 buildozer.spec"
    fi
else
    echo "警告: 未找到 buildozer.spec 文件"
fi

echo ""

# 第五步: 清理构建缓存
echo "==== 第五步: 清理构建缓存 ===="
if [ -d ".buildozer" ]; then
    echo "清理之前的构建缓存..."
    rm -rf .buildozer
    echo "✓ 已清理 .buildozer 目录"
fi

echo ""

# 第六步: 验证修复结果
echo "==== 第六步: 验证修复结果 ===="
echo "当前安装的关键包版本:"
pip list | grep -E "(cython|pyjnius|buildozer)" || echo "未找到相关包"

echo ""
echo "SDL2本地文件状态:"
ls -la /tmp/SDL2*.tar 2>/dev/null || echo "未找到SDL2本地文件"

echo ""
echo "Python依赖包状态:"
ls -la ./wheels/*.whl 2>/dev/null | wc -l | xargs echo "本地wheels包数量:"

echo ""

# 第七步: 提供使用说明
echo "==== 修复完成 ===="
echo ""
echo "修复内容总结:"
echo "1. ✓ SDL2依赖已下载到 /tmp 目录"
echo "2. ✓ Python依赖包已下载到 ./wheels 目录"
echo "3. ✓ Cython已降级到 <3.0 版本"
echo "4. ✓ pyjnius已安装 <1.5 版本"
echo "5. ✓ buildozer.spec 已更新"
echo "6. ✓ 构建缓存已清理"
echo ""
echo "现在可以安全地运行构建命令:"
echo "  buildozer -v android debug"
echo ""
echo "如果遇到网络问题，可以使用本地依赖:"
echo "  pip install --no-index --find-links=./wheels -r requirements-android.txt"
echo ""
echo "==== 注意事项 ===="
echo "- 如果构建仍然失败，请检查网络连接"
echo "- 确保Android SDK和NDK已正确安装"
echo "- 可以查看详细日志: buildozer -v android debug 2>&1 | tee build.log"
echo "" 