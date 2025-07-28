#!/bin/bash
# 分析打包程序内容的脚本

echo "==== 打包程序内容分析 ===="
echo ""

# 基本信息
echo "1. 基本信息："
echo "   文件路径: test_dist/translate-chat-test"
echo "   文件大小: $(ls -lh test_dist/translate-chat-test | awk '{print $5}')"
echo "   文件类型: $(file test_dist/translate-chat-test | cut -d: -f2-)"
echo ""

# 动态库依赖
echo "2. 动态库依赖："
otool -L test_dist/translate-chat-test
echo ""

# 架构信息
echo "3. 架构信息："
lipo -info test_dist/translate-chat-test 2>/dev/null || echo "   单架构文件"
echo ""

# 符号表信息
echo "4. 符号表信息："
nm test_dist/translate-chat-test | grep -E "(main|PyMain|kivy|translate)" | head -10
echo ""

# 文件头信息
echo "5. 文件头信息："
otool -hv test_dist/translate-chat-test | head -10
echo ""

# 检查是否包含Python解释器
echo "6. Python解释器检查："
strings test_dist/translate-chat-test | grep -i "python" | head -5
echo ""

# 检查是否包含Kivy相关字符串
echo "7. Kivy相关检查："
strings test_dist/translate-chat-test | grep -i "kivy" | head -5
echo ""

echo "==== 分析完成 ====" 