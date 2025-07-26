# Android 构建问题修复指南 / Android Build Issue Fix Guide

## 问题描述 / Problem Description

在Android打包过程中，经常遇到以下问题：

1. **网络下载失败**：SDL2依赖包下载失败
2. **pyjnius编译错误**：`long`类型未定义，Cython版本兼容性问题
3. **依赖包版本冲突**：新版本包与旧版本不兼容

## 解决方案 / Solutions

### 1. 完整修复脚本（推荐） / Complete Fix Script (Recommended)

使用 `complete_build_fix.sh` 脚本，一次性解决所有问题：

```bash
# 激活虚拟环境
source venv/bin/activate

# 运行完整修复脚本
bash scripts/complete_build_fix.sh
```

**此脚本会自动执行以下操作：**
- 下载SDL2相关依赖到 `/tmp` 目录
- 下载Python依赖包到 `./wheels` 目录
- 降级Cython到兼容版本（<3.0）
- 安装兼容的pyjnius版本（<1.5）
- 更新buildozer.spec配置
- 清理构建缓存

### 2. 分步修复 / Step-by-step Fix

如果只需要解决特定问题，可以使用专门的脚本：

#### 2.1 依赖包本地化 / Dependency Localization

```bash
# 下载SDL2依赖
bash scripts/sdl2_local_manager.sh

# 下载Python依赖包
bash scripts/dependency_manager.sh
```

#### 2.2 pyjnius编译问题修复 / pyjnius Compilation Fix

```bash
# 修复pyjnius编译问题
bash scripts/fix_pyjnius_issue.sh
```

### 3. 手动修复 / Manual Fix

如果脚本无法解决问题，可以手动执行以下步骤：

#### 3.1 降级Cython版本

```bash
pip uninstall -y cython
pip install "cython<3.0"
```

#### 3.2 安装兼容的pyjnius版本

```bash
pip uninstall -y pyjnius
pip install "pyjnius<1.5"
```

#### 3.3 更新requirements文件

在 `requirements-android.txt` 中添加：

```
cython<3.0
pyjnius<1.5
```

#### 3.4 更新buildozer.spec

在 `buildozer.spec` 的 `requirements` 行中添加版本限制：

```
requirements = python3,kivy>=2.3.0,kivymd==1.1.1,plyer>=2.1.0,ffpyplayer>=4.5.0,websocket-client,aiohttp,cython<3.0,pyjnius<1.5
```

## 使用本地依赖 / Using Local Dependencies

### 1. 使用本地wheels包

```bash
# 安装本地依赖包
pip install --no-index --find-links=./wheels -r requirements-android.txt
```

### 2. 使用本地SDL2文件

确保以下文件存在于 `/tmp` 目录：
- `SDL2-2.28.5.tar`
- `SDL2_image-2.8.0.tar`
- `SDL2_mixer-2.6.3.tar`
- `SDL2_ttf-2.20.2.tar`

## 构建命令 / Build Commands

修复完成后，使用以下命令进行构建：

```bash
# 标准构建
buildozer -v android debug

# 详细日志构建（推荐用于调试）
buildozer -v android debug 2>&1 | tee build.log

# 清理后重新构建
buildozer android clean
buildozer -v android debug
```

## 常见问题 / Common Issues

### 1. 网络连接问题

**症状：** 下载失败，连接超时
**解决：** 使用本地依赖包，或配置代理

### 2. Cython编译错误

**症状：** `long`类型未定义，语法错误
**解决：** 降级Cython到 <3.0 版本

### 3. pyjnius编译失败

**症状：** 找不到jnius.c文件，编译错误
**解决：** 安装pyjnius <1.5 版本

### 4. 权限问题

**症状：** 无法写入文件，权限被拒绝
**解决：** 检查文件权限，确保可写

## 环境要求 / Environment Requirements

- Python 3.8+
- Ubuntu 18.04+ 或 macOS 10.15+
- Java 8
- Android SDK/NDK（由buildozer自动下载）

## 故障排除 / Troubleshooting

### 1. 查看详细日志

```bash
# 设置详细日志级别
export PYTHONPATH="${PYTHONPATH}:$(pwd)"
buildozer -v android debug 2>&1 | tee build.log
```

### 2. 检查环境变量

```bash
# 检查关键环境变量
echo "JAVA_HOME: $JAVA_HOME"
echo "ANDROID_HOME: $ANDROID_HOME"
echo "PATH: $PATH"
```

### 3. 验证依赖安装

```bash
# 检查关键包版本
pip list | grep -E "(cython|pyjnius|buildozer|kivy)"
```

## 联系支持 / Support

如果问题仍然存在，请：

1. 查看完整构建日志
2. 检查系统环境信息
3. 提供错误截图或日志文件

---

**注意：** 这些修复脚本会修改您的项目配置，建议在运行前备份重要文件。 