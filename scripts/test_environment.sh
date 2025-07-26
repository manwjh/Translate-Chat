#!/bin/bash
# 测试环境检查函数

set -e

# 引入通用函数
source ./scripts/common_build_utils.sh

echo "==== 测试环境检查函数 ===="

# 测试系统检测
echo "1. 测试系统检测..."
system=$(detect_system)
echo "检测到的系统: $system"

# 测试Python版本检测
echo "2. 测试Python版本检测..."
if check_python_version "python3"; then
    echo "Python版本检查通过"
else
    echo "Python版本检查失败"
fi

# 测试环境检查
echo "3. 测试环境检查..."
result=$(check_environment)
exit_code=$?
echo "环境检查结果: $exit_code"
echo "返回的Python命令: '$result'"

if [[ $exit_code -eq 0 ]]; then
    echo "环境检查成功"
else
    echo "环境检查失败"
fi 