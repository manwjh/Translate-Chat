#!/bin/bash
# Translate Chat - gradlew快速修复脚本
# 文件名(File): quick_fix_gradlew.sh
# 版本(Version): v1.0.0
# 创建日期(Created): 2025/1/27
# 简介(Description): 快速修复gradlew失败问题，适用于Linux+x86平台

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "==== gradlew快速修复脚本 ===="
echo "开始时间: $(date)"
echo ""

# 1. 清理损坏的构建目录
log_info "步骤1: 清理损坏的构建目录..."
if [[ -d ".buildozer/android/platform/build-arm64-v8a_armeabi-v7a" ]]; then
    rm -rf .buildozer/android/platform/build-arm64-v8a_armeabi-v7a
    log_success "已清理损坏的构建目录"
fi

# 2. 清理空的dist目录
log_info "步骤2: 清理空的dist目录..."
find .buildozer -path "*/dists/translatechat" -type d -empty -delete 2>/dev/null || true
log_success "已清理空的dist目录"

# 3. 修复权限问题
log_info "步骤3: 修复权限问题..."
if [[ -d ".buildozer" ]]; then
    chmod -R 755 .buildozer
    log_success "已修复.buildozer目录权限"
fi

# 4. 设置Java环境
log_info "步骤4: 设置Java环境..."
if [[ -d "/usr/lib/jvm/java-11-openjdk-amd64" ]]; then
    export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
    export PATH="$JAVA_HOME/bin:$PATH"
    log_success "设置JAVA_HOME为: $JAVA_HOME"
elif [[ -d "/usr/lib/jvm/java-17-openjdk-amd64" ]]; then
    export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
    export PATH="$JAVA_HOME/bin:$PATH"
    log_success "设置JAVA_HOME为: $JAVA_HOME"
else
    log_warning "未找到合适的Java环境，请确保已安装Java 11或17"
fi

# 5. 配置国内镜像
log_info "步骤5: 配置国内镜像..."
mkdir -p ~/.gradle
cat > ~/.gradle/init.gradle << 'EOF'
allprojects {
    repositories {
        def ALIYUN_REPOSITORY_URL = 'https://maven.aliyun.com/repository/public'
        def ALIYUN_JCENTER_URL = 'https://maven.aliyun.com/repository/jcenter'
        all { ArtifactRepository repo ->
            if(repo instanceof MavenArtifactRepository){
                def url = repo.url.toString()
                if (url.startsWith('https://repo1.maven.org/maven2/')) {
                    project.logger.lifecycle "Repository ${repo.name} replaced by $ALIYUN_REPOSITORY_URL."
                    remove repo
                }
                if (url.startsWith('https://jcenter.bintray.com/')) {
                    project.logger.lifecycle "Repository ${repo.name} replaced by $ALIYUN_JCENTER_URL."
                    remove repo
                }
            }
        }
        maven { url ALIYUN_REPOSITORY_URL }
        maven { url ALIYUN_JCENTER_URL }
    }
}
EOF
log_success "已配置Gradle国内镜像"

# 6. 配置pip镜像
log_info "步骤6: 配置pip镜像..."
mkdir -p ~/.pip
cat > ~/.pip/pip.conf << 'EOF'
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
trusted-host = pypi.tuna.tsinghua.edu.cn
timeout = 120
EOF
log_success "已配置pip国内镜像"

# 7. 激活虚拟环境并确保依赖
log_info "步骤7: 检查Python环境..."
if [[ -d "venv" ]]; then
    source venv/bin/activate
    pip install --upgrade pip setuptools wheel
    pip install cython==0.29.36 buildozer==1.5.0
    log_success "Python环境检查完成"
else
    log_warning "虚拟环境不存在，请先运行: python3 -m venv venv"
fi

# 8. 应用pyjnius补丁（如果需要）
log_info "步骤8: 检查pyjnius补丁..."
if [[ -f "scripts/pyjnius_patch.sh" ]]; then
    bash scripts/pyjnius_patch.sh
    log_success "pyjnius补丁检查完成"
else
    log_warning "未找到pyjnius补丁脚本"
fi

echo ""
log_success "快速修复完成！"
echo ""
log_info "现在请按以下步骤重新构建:"
echo "1. 清理构建缓存: buildozer android clean"
echo "2. 重新构建: buildozer android debug"
echo ""
log_info "如果仍然失败，请检查:"
echo "- 网络连接是否正常"
echo "- 磁盘空间是否充足"
echo "- Java版本是否为11或17"
echo "- Python版本是否为3.9-3.11"
echo ""
echo "==== 修复完成 ===="
echo "结束时间: $(date)" 