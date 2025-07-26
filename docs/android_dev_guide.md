# Translate Chat - Android 开发、运行与打包指南

**适用平台**：推荐 Ubuntu 20.04/22.04、Debian、macOS（部分步骤略有不同）  
**适用版本**：v0.1.1 及以上

---

## 1. 推荐开发环境

- **操作系统**：Linux（如 Ubuntu 20.04/22.04）优先，macOS 亦可
- **Python 版本**：3.7 ~ 3.10（建议 3.8/3.9）
- **Kivy**：>=2.3.0
- **KivyMD**：==1.1.1
- **Buildozer**：用于打包 APK，仅支持 Linux/macOS

> Windows 不建议直接开发和打包 Android 版（可用 WSL2，但更复杂）

---

## 2. 环境准备与依赖安装

### 2.1 安装系统依赖

```bash
sudo apt update
sudo apt install -y python3 python3-venv python3-pip git \
    openjdk-8-jdk unzip zlib1g-dev libncurses5 libstdc++6 \
    libffi-dev libssl-dev
```

### 2.2 创建 Python 虚拟环境

```bash
python3 -m venv venv
source venv/bin/activate
```

### 2.3 安装 Python 依赖

```bash
pip install --upgrade pip cython
pip install buildozer
```

---

## 3. 配置 Buildozer

### 3.1 初始化 Buildozer 配置

```bash
buildozer init
```

- 会生成 `buildozer.spec` 文件
- 编辑 `buildozer.spec`，确保如下内容：
  - `requirements` 字段包含：kivy, kivymd, websocket-client, aiohttp, 及其它依赖
  - `source.include_exts` 包含 `.py,.kv,.ttf,.json` 等
  - `android.permissions` 根据需要添加（如 RECORD_AUDIO, INTERNET）
  - `android.arch` 建议 arm64-v8a

### 3.2 依赖文件

- Android 依赖见 `requirements-android.txt`，可参考内容补充到 `buildozer.spec` 的 `requirements` 字段

---

## 4. 打包 APK

### 4.1 下载 Android SDK/NDK

- Buildozer 首次打包会自动下载 Android SDK/NDK，需科学上网或提前手动下载

### 4.2 打包命令

```bash
buildozer -v android debug
```

- 首次打包时间较长，需联网
- 生成的 APK 在 `bin/` 目录下

### 4.3 安装到设备

```bash
buildozer android deploy run
```

- 需连接 Android 设备并开启 USB 调试

---

## 5. 运行与调试

- 可用 Android 模拟器或真机测试
- 日志查看：

```bash
buildozer android logcat
```

---

## 6. 常见问题与解决

- **SDK/NDK 下载失败**：需科学上网，或手动下载后配置环境变量
- **依赖打包失败**：检查 `requirements` 字段拼写，避免不支持的包
- **权限问题**：确保 `android.permissions` 配置正确
- **APK 安装失败**：检查设备架构与 `android.arch` 设置是否匹配
- **界面乱码/字体不全**：确保字体文件已包含在 `source.include_exts` 和 `assets/fonts/` 目录

---

## 7. 参考链接

- [Kivy 官方 Android 打包指南](https://kivy.org/doc/stable/guide/packaging-android.html)
- [Buildozer 官方文档](https://buildozer.readthedocs.io/en/latest/)
- [KivyMD 官方文档](https://kivymd.readthedocs.io/en/latest/)

---

如有问题请联系：manwjh@126.com 

---

## 8. macOS 自动化打包脚本

项目根目录下的 `scripts/build_android_macos.sh` 可一键完成依赖安装、环境配置与 APK 打包：

```bash
bash scripts/build_android_macos.sh
```

如遇权限问题，先赋予可执行权限：

```bash
chmod +x scripts/build_android_macos.sh
``` 