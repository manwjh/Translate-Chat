#!/bin/bash
# main.py 找不到问题修复脚本 / main.py Not Found Issue Fix Script
# 文件名(File): fix_main_py_issue.sh
# 版本(Version): v1.0.0
# 作者(Author): AI Assistant
# 创建日期(Created): 2025/1/27
# 简介(Description): 修复buildozer找不到main.py的问题

set -e

echo "==== main.py 找不到问题修复脚本 ===="
echo "==== main.py Not Found Issue Fix Script ===="
echo ""

# 检查当前目录
echo "当前工作目录: $(pwd)"
echo ""

# 查找main.py文件
if [ -f "main.py" ]; then
    echo "✓ 在当前目录找到 main.py"
    echo "当前目录就是项目根目录，无需切换"
elif [ -f "../main.py" ]; then
    echo "⚠ 在上级目录找到 main.py"
    echo "正在切换到项目根目录..."
    cd ..
    echo "✓ 已切换到项目根目录: $(pwd)"
elif [ -f "../../main.py" ]; then
    echo "⚠ 在上上级目录找到 main.py"
    echo "正在切换到项目根目录..."
    cd ../..
    echo "✓ 已切换到项目根目录: $(pwd)"
else
    echo "✗ 未找到 main.py 文件"
    echo "请确保在正确的项目目录中运行此脚本"
    echo ""
    echo "项目结构应该是:"
    echo "Translate-Chat/"
    echo "├── main.py"
    echo "├── buildozer.spec"
    echo "└── scripts/"
    echo "    └── fix_main_py_issue.sh"
    echo ""
    exit 1
fi

# 验证项目结构
echo ""
echo "验证项目结构..."
if [ ! -f "buildozer.spec" ]; then
    echo "✗ 未找到 buildozer.spec 文件"
    echo "请确保在正确的项目根目录中"
    exit 1
fi

if [ ! -d "scripts" ]; then
    echo "✗ 未找到 scripts 目录"
    echo "请确保在正确的项目根目录中"
    exit 1
fi

echo "✓ 项目结构验证通过"
echo ""

# 检查buildozer.spec中的source.dir配置
echo "检查 buildozer.spec 配置..."
if grep -q "^source\.dir = \." buildozer.spec; then
    echo "✓ source.dir 配置正确 (当前目录)"
else
    echo "⚠ source.dir 配置可能有问题"
    echo "当前配置:"
    grep "^source\.dir" buildozer.spec || echo "未找到 source.dir 配置"
fi

echo ""

# 提供解决方案
echo "==== 解决方案 ===="
echo ""
echo "现在您可以在当前目录运行 buildozer:"
echo ""
echo "1. 确保虚拟环境已激活:"
echo "   source venv/bin/activate"
echo ""
echo "2. 运行构建命令:"
echo "   buildozer -v android debug"
echo ""
echo "3. 或者使用修复脚本:"
echo "   bash scripts/complete_build_fix.sh"
echo ""

# 检查是否在虚拟环境中
if [ -z "$VIRTUAL_ENV" ]; then
    echo "⚠ 警告: 未检测到虚拟环境"
    echo "建议先激活虚拟环境:"
    echo "   source venv/bin/activate"
    echo ""
fi

echo "==== 修复完成 ===="
echo "当前目录: $(pwd)"
echo "main.py 状态: $(ls -la main.py 2>/dev/null || echo '未找到')"
echo "buildozer.spec 状态: $(ls -la buildozer.spec 2>/dev/null || echo '未找到')"
echo "" 