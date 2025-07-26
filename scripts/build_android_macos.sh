#!/bin/bash
# Translate Chat - macOS Android 打包自动化脚本
set -e

# 配置 pip 全局镜像（清华源）
echo "==== 0. 配置 pip 国内镜像 ===="
mkdir -p ~/.pip
cat > ~/.pip/pip.conf <<EOF
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
EOF

# 检查 openssl@1.1 路径并自动设置环境变量
if [ -d "/usr/local/opt/openssl@1.1" ]; then
  export LDFLAGS="-L/usr/local/opt/openssl@1.1/lib"
  export CPPFLAGS="-I/usr/local/opt/openssl@1.1/include"
  export PKG_CONFIG_PATH="/usr/local/opt/openssl@1.1/lib/pkgconfig"
  echo "==== openssl@1.1 路径: /usr/local/opt/openssl@1.1，已设置环境变量 ===="
elif [ -d "/opt/homebrew/opt/openssl@1.1" ]; then
  export LDFLAGS="-L/opt/homebrew/opt/openssl@1.1/lib"
  export CPPFLAGS="-I/opt/homebrew/opt/openssl@1.1/include"
  export PKG_CONFIG_PATH="/opt/homebrew/opt/openssl@1.1/lib/pkgconfig"
  echo "==== openssl@1.1 路径: /opt/homebrew/opt/openssl@1.1，已设置环境变量 ===="
else
  echo "==== 未检测到 openssl@1.1，请先手动编译安装 ===="
  exit 1
fi

# 优先使用 JDK 17
if brew list --versions openjdk@17 >/dev/null; then
  echo "==== 1. openjdk@17 已安装 ===="
else
  echo "==== 1. 安装 openjdk@17（如有 JDK 11/24 建议先卸载） ===="
  brew install openjdk@17
fi
export JAVA_HOME="/opt/homebrew/opt/openjdk@17"
export PATH="$JAVA_HOME/bin:$PATH"
echo "JAVA_HOME set to $JAVA_HOME"

# 依赖安装
brew install python@3.9 git

# 创建/激活虚拟环境
if [ ! -d venv ]; then
  /opt/homebrew/bin/python3.9 -m venv venv
fi
source venv/bin/activate

# 再次 export 关键环境变量，确保 venv 内可见
export LDFLAGS
export CPPFLAGS
export PKG_CONFIG_PATH
export JAVA_HOME
export PATH

echo "==== 2. 安装 Python 依赖 ===="
pip install --upgrade pip cython buildozer

echo "==== 3. 初始化 buildozer.spec（如未存在） ===="
if [ ! -f buildozer.spec ]; then
  buildozer init
fi

echo "==== 4. 开始打包 APK ===="
buildozer -v android debug

echo "==== 5. APK 生成于 bin/ 目录 ===="
ls -lh bin/*.apk

echo "==== 6. 如需部署到设备，请连接设备并执行：buildozer android deploy run ====" 