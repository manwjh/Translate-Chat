#!/bin/bash
# Translate Chat - Android构建修复脚本
# 文件名(File): fix_android_build.sh
# 版本(Version): v1.0.0
# 创建日期(Created): 2025/1/27
# 简介(Description): 修复Android构建过程中的常见问题，特别是gradlew失败问题

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

# 检查系统类型
detect_system() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ -f /etc/os-release ]]; then
        if grep -q "Ubuntu" /etc/os-release; then
            echo "ubuntu"
        else
            echo "linux"
        fi
    else
        echo "unknown"
    fi
}

# 修复权限问题
fix_permissions() {
    log_info "修复权限问题..."
    
    # 修复buildozer目录权限
    if [[ -d ".buildozer" ]]; then
        chmod -R 755 .buildozer
        log_success "已修复.buildozer目录权限"
    fi
    
    # 修复gradlew文件权限（如果存在）
    find .buildozer -name "gradlew" -type f -exec chmod +x {} \; 2>/dev/null || true
    log_success "已修复gradlew文件权限"
}

# 清理损坏的构建缓存
clean_corrupted_build() {
    log_info "清理损坏的构建缓存..."
    
    # 清理空的dist目录
    find .buildozer -path "*/dists/translatechat" -type d -empty -delete 2>/dev/null || true
    
    # 清理损坏的构建目录
    if [[ -d ".buildozer/android/platform/build-arm64-v8a_armeabi-v7a" ]]; then
        local build_dir=".buildozer/android/platform/build-arm64-v8a_armeabi-v7a"
        if [[ ! -f "$build_dir/dists/translatechat/gradlew" ]]; then
            log_warning "检测到损坏的构建目录，正在清理..."
            rm -rf "$build_dir"
            log_success "已清理损坏的构建目录"
        fi
    fi
}

# 修复Java环境
fix_java_environment() {
    log_info "修复Java环境..."
    
    local system=$(detect_system)
    
    if [[ "$system" == "ubuntu" ]]; then
        # Ubuntu系统Java环境修复
        if [[ -d "/usr/lib/jvm/java-11-openjdk-amd64" ]]; then
            export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
            export PATH="$JAVA_HOME/bin:$PATH"
            log_success "设置JAVA_HOME为: $JAVA_HOME"
        elif [[ -d "/usr/lib/jvm/java-17-openjdk-amd64" ]]; then
            export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
            export PATH="$JAVA_HOME/bin:$PATH"
            log_success "设置JAVA_HOME为: $JAVA_HOME"
        else
            log_warning "未找到合适的Java环境，尝试安装..."
            sudo apt update
            sudo apt install -y openjdk-11-jdk
            export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
            export PATH="$JAVA_HOME/bin:$PATH"
            log_success "已安装并设置Java 11"
        fi
    elif [[ "$system" == "macos" ]]; then
        # macOS系统Java环境修复
        if [[ -d "/opt/homebrew/opt/openjdk@17" ]]; then
            export JAVA_HOME="/opt/homebrew/opt/openjdk@17"
            export PATH="$JAVA_HOME/bin:$PATH"
            log_success "设置JAVA_HOME为: $JAVA_HOME"
        elif [[ -d "/usr/local/opt/openjdk@17" ]]; then
            export JAVA_HOME="/usr/local/opt/openjdk@17"
            export PATH="$JAVA_HOME/bin:$PATH"
            log_success "设置JAVA_HOME为: $JAVA_HOME"
        else
            log_warning "未找到合适的Java环境，请手动安装Java 11或17"
        fi
    fi
}

# 修复Python环境
fix_python_environment() {
    log_info "修复Python环境..."
    
    # 检查虚拟环境
    if [[ ! -d "venv" ]]; then
        log_warning "虚拟环境不存在，正在创建..."
        python3 -m venv venv
        log_success "已创建虚拟环境"
    fi
    
    # 激活虚拟环境
    source venv/bin/activate
    
    # 升级pip和安装必要依赖
    pip install --upgrade pip setuptools wheel
    pip install cython==0.29.36
    pip install buildozer==1.5.0
    
    log_success "Python环境修复完成"
}

# 修复buildozer配置
fix_buildozer_config() {
    log_info "修复buildozer配置..."
    
    # 备份原配置
    if [[ -f "buildozer.spec" ]]; then
        cp buildozer.spec buildozer.spec.backup
        log_success "已备份buildozer.spec"
    fi
    
    # 检查并修复关键配置
    local temp_spec=$(mktemp)
    
    cat > "$temp_spec" << 'EOF'
[app]
title = Translate-Chat
package.name = translatechat
package.domain = org.translatechat
source.dir = .
source.include_exts = py,png,jpg,kv,atlas,json,md,ttf
source.include_patterns = assets/*
source.exclude_dirs = tests,bin,venv,.git,.buildozer
version = 0.1.1

# Python依赖
requirements = python3,kivy>=2.3.0,kivymd==1.1.1,plyer>=2.1.0,ffpyplayer>=4.5.0,websocket-client,aiohttp

# 应用配置
orientation = portrait
fullscreen = 0
android.allow_backup = True

# Android权限
android.permissions = INTERNET,RECORD_AUDIO,WRITE_EXTERNAL_STORAGE,READ_EXTERNAL_STORAGE,WAKE_LOCK

# Android版本配置
android.api = 31
android.minapi = 21
android.ndk = 25b
android.archs = arm64-v8a, armeabi-v7a

# 应用图标和启动画面
android.presplash_color = #FFFFFF
android.icon.filename = %(source.dir)s/icon.png
android.presplash.filename = %(source.dir)s/presplash.png

# 应用标签和描述
android.app_name = Translate-Chat
android.label = Translate-Chat

# 构建配置
android.accept_sdk_license = True
android.allow_newer_sdk = True

# 调试配置
android.debug_build = True
android.release_artifact = apk

# 网络配置
android.enable_androidx = True

# 日志配置
log_level = 2

# 修复gradlew问题的配置
android.gradle_dependencies = 'androidx.appcompat:appcompat:1.6.1'
android.add_aars = ~/.gradle/caches/modules-2/files-2.1/androidx.appcompat/appcompat/1.6.1/*.aar

# 确保gradlew可执行
android.gradle_executable = gradlew
EOF
    
    # 如果原配置存在，合并关键修复
    if [[ -f "buildozer.spec.backup" ]]; then
        # 保留原配置，只添加修复项
        cp buildozer.spec.backup buildozer.spec
        echo "" >> buildozer.spec
        echo "# 修复配置" >> buildozer.spec
        echo "android.gradle_dependencies = 'androidx.appcompat:appcompat:1.6.1'" >> buildozer.spec
        echo "android.gradle_executable = gradlew" >> buildozer.spec
    else
        mv "$temp_spec" buildozer.spec
    fi
    
    log_success "buildozer配置修复完成"
}

# 修复网络和代理问题
fix_network_issues() {
    log_info "修复网络和代理问题..."
    
    # 设置国内镜像
    export PIP_INDEX_URL="https://pypi.tuna.tsinghua.edu.cn/simple"
    export PIP_TRUSTED_HOST="pypi.tuna.tsinghua.edu.cn"
    
    # 配置gradle镜像
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
    
    log_success "网络配置修复完成"
}

# 主修复函数
main_fix() {
    echo "==== Android构建修复脚本 ===="
    echo "开始时间: $(date)"
    echo ""
    
    # 确保在项目根目录
    if [[ ! -f "main.py" ]]; then
        log_error "请在项目根目录运行此脚本"
        exit 1
    fi
    
    log_info "开始修复Android构建问题..."
    
    # 1. 修复权限问题
    fix_permissions
    
    # 2. 清理损坏的构建缓存
    clean_corrupted_build
    
    # 3. 修复Java环境
    fix_java_environment
    
    # 4. 修复Python环境
    fix_python_environment
    
    # 5. 修复buildozer配置
    fix_buildozer_config
    
    # 6. 修复网络问题
    fix_network_issues
    
    echo ""
    log_success "修复完成！"
    log_info "现在可以尝试重新运行构建:"
    echo "  buildozer android clean"
    echo "  buildozer android debug"
    echo ""
    echo "==== 修复完成 ===="
    echo "结束时间: $(date)"
}

# 执行修复
main_fix 