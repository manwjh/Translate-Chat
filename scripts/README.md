# Translate Chat - Android 打包脚本说明

**文件名(File):** README.md  
**版本(Version):** v0.1.0  
**作者(Author):** 深圳王哥 & AI  
**创建日期(Created):** 2025/1/27  
**简介(Description):** Ubuntu和macOS环境下Android APK自动化打包脚本使用指南

---

## 脚本文件说明

### 1. Ubuntu环境脚本
- **文件名:** `build_android_ubuntu.sh`
- **适用系统:** Ubuntu 20.04/22.04 及衍生版本
- **特点:** 官方支持最佳，配置简单，性能最优

### 2. macOS环境脚本  
- **文件名:** `build_android_macos.sh`
- **适用系统:** macOS 10.15+ (Catalina及以上)
- **特点:** 项目已优化，提供自动化配置

---

## 使用方法

### Ubuntu环境
```bash
# 1. 给脚本添加执行权限
chmod +x scripts/build_android_ubuntu.sh

# 2. 运行打包脚本
bash scripts/build_android_ubuntu.sh
```

### macOS环境
```bash
# 1. 给脚本添加执行权限
chmod +x scripts/build_android_macos.sh

# 2. 运行打包脚本
bash scripts/build_android_macos.sh
```

---

## 脚本功能对比

| 功能 | Ubuntu脚本 | macOS脚本 |
|------|------------|-----------|
| 系统检测 | ✅ 自动检测Ubuntu | ❌ 无系统检测 |
| 依赖安装 | ✅ 自动安装所有依赖 | ✅ 自动安装依赖 |
| 镜像配置 | ✅ 清华源 | ✅ 清华源 |
| Java配置 | ✅ OpenJDK 8 | ✅ OpenJDK 17 |
| 虚拟环境 | ✅ 自动创建 | ✅ 自动创建 |
| 构建清理 | ✅ 自动清理 | ❌ 无清理 |
| 结果检查 | ✅ 详细检查 | ❌ 基础检查 |
| 自动部署 | ✅ 可选部署 | ❌ 无部署选项 |

---

## buildozer.spec 共用说明

**是的，两个脚本可以共用同一个 `buildozer.spec` 文件！**

### 原因：
1. **跨平台兼容:** buildozer.spec 是纯文本配置文件，不依赖特定操作系统
2. **统一配置:** 应用名称、版本、权限等配置在不同平台下保持一致
3. **维护简单:** 只需要维护一个配置文件，减少出错概率

### 当前配置特点：
- **Python依赖:** 指定了精确的版本要求
- **Android权限:** 包含应用所需的所有权限
- **资源文件:** 自动包含assets目录下的所有文件
- **排除目录:** 避免打包不必要的文件

---

## 环境要求

### Ubuntu环境
- **系统:** Ubuntu 20.04/22.04
- **Python:** 3.7-3.10 (推荐3.8/3.9)
- **Java:** OpenJDK 8
- **内存:** 建议4GB以上
- **磁盘:** 建议10GB以上可用空间

### macOS环境
- **系统:** macOS 10.15+ (Catalina及以上)
- **Python:** 3.7-3.10 (推荐3.8/3.9)
- **Java:** OpenJDK 17
- **内存:** 建议4GB以上
- **磁盘:** 建议10GB以上可用空间

---

## 常见问题

### 1. 首次打包时间很长
**原因:** 需要下载Android SDK/NDK (约2-3GB)
**解决:** 使用科学上网工具或耐心等待

### 2. 依赖安装失败
**原因:** 网络问题或版本冲突
**解决:** 检查网络连接，清理虚拟环境重新安装

### 3. Java版本问题
**Ubuntu:** 脚本自动配置OpenJDK 8
**macOS:** 脚本自动配置OpenJDK 17

### 4. 权限问题
**解决:** 确保脚本有执行权限 `chmod +x scripts/*.sh`

---

## 推荐使用顺序

1. **首选:** Ubuntu环境 (官方支持最佳)
2. **备选:** macOS环境 (项目已优化)
3. **不推荐:** Windows环境 (需要WSL2，配置复杂)

---

## 联系支持

如有问题请联系：manwjh@126.com 