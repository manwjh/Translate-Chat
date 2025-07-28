#!/bin/bash
# 简化的Linux构建测试脚本

set -e

echo "==== 简化Linux构建测试 ===="
echo "开始时间: $(date)"
echo ""

# 检查环境
echo "1. 检查环境..."
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "错误: 此脚本仅适用于macOS系统"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo "错误: Docker未安装"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo "错误: Docker未运行"
    exit 1
fi

echo "✓ 环境检查通过"

# 创建简单的Dockerfile
echo "2. 创建测试Dockerfile..."
cat > Dockerfile.test << 'EOF'
FROM ubuntu:22.04

# 安装Python
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /app

# 复制项目文件
COPY . /app/

# 安装依赖
RUN pip3 install --no-cache-dir pyinstaller==5.13.2

# 创建简单的构建脚本
RUN cat > /app/build_test.sh << 'SCRIPT_EOF'
#!/bin/bash
echo "开始构建测试..."
pyinstaller --onefile --name="test-app" main.py
echo "构建完成！"
ls -la dist/
SCRIPT_EOF

RUN chmod +x /app/build_test.sh

# 设置入口点
ENTRYPOINT ["/app/build_test.sh"]
EOF

echo "✓ Dockerfile创建完成"

# 构建Docker镜像
echo "3. 构建Docker镜像..."
if docker build -f Dockerfile.test -t translate-chat-test .; then
    echo "✓ Docker镜像构建成功"
else
    echo "✗ Docker镜像构建失败"
    exit 1
fi

# 运行测试构建
echo "4. 运行测试构建..."
mkdir -p test_build
if docker run --rm \
    -v "$(pwd)/test_build:/app/dist" \
    translate-chat-test; then
    echo "✓ 测试构建成功"
else
    echo "✗ 测试构建失败"
    exit 1
fi

# 检查结果
echo "5. 检查构建结果..."
if [[ -f "test_build/test-app" ]]; then
    echo "✓ 可执行文件生成成功"
    ls -lh test_build/test-app
else
    echo "✗ 可执行文件生成失败"
    exit 1
fi

# 清理
echo "6. 清理..."
docker rmi translate-chat-test 2>/dev/null || true
rm -f Dockerfile.test
rm -rf test_build

echo ""
echo "==== 测试完成 ===="
echo "结束时间: $(date)"
echo "✓ 所有测试通过！" 