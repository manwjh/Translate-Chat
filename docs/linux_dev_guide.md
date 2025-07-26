# Translate Chat - Linux 开发、运行与打包指南

**适用平台**：Ubuntu/Debian/Fedora/Arch 等主流 Linux 发行版  
**适用版本**：v0.1.1 及以上

---

## 1. 环境准备

### 1.1 安装 Python 3.7+

建议使用系统包管理器或 [pyenv](https://github.com/pyenv/pyenv) 安装。

```bash
sudo apt update
sudo apt install python3 python3-venv python3-pip
# 或 pyenv 安装
```

### 1.2 安装依赖库

#### 1.2.1 系统依赖（音频/图形相关）

```bash
# Ubuntu/Debian
sudo apt install portaudio19-dev libgl1-mesa-dev libgles2-mesa-dev \
                 libgstreamer1.0-dev libmtdev-dev \
                 libffi-dev libssl-dev libjpeg-dev zlib1g-dev \
                 libfreetype6-dev liblcms2-dev libopenjp2-7-dev \
                 libtiff5-dev libwebp-dev libharfbuzz-dev libfribidi-dev \
                 libxcb1-dev

# Fedora
sudo dnf install portaudio-devel mesa-libGL-devel mesa-libGLES-devel \
                 gstreamer1-devel mtdev-devel \
                 libffi-devel openssl-devel libjpeg-turbo-devel zlib-devel \
                 freetype-devel lcms2-devel openjpeg2-devel \
                 libtiff-devel libwebp-devel harfbuzz-devel fribidi-devel \
                 libxcb-devel
```

#### 1.2.2 Python 虚拟环境与依赖

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements-desktop.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
```

> 推荐使用国内镜像源加速依赖下载。

---

## 2. 配置 API 密钥

- 复制 `config_template.py` 为 `config.py`，填写火山 ASR/LLM 密钥
- 或设置环境变量（推荐）

```bash
export ASR_APP_KEY=你的ASR_APP_KEY
export ASR_ACCESS_KEY=你的ASR_ACCESS_KEY
export LLM_API_KEY=你的LLM_API_KEY
```

---

## 3. 运行项目

### 3.1 推荐方式

```bash
bash run.sh
```

### 3.2 手动运行

```bash
source venv/bin/activate
python3 main.py
```

---

## 4. 打包为 Linux 可执行文件

### 4.1 使用 PyInstaller 打包

#### 4.1.1 安装 PyInstaller

```bash
pip install pyinstaller
```

#### 4.1.2 打包命令

```bash
pyinstaller --onefile --noconsole --add-data "assets/fonts:NotoSansSC-VariableFont_wght.ttf" main.py
```

- `--onefile`：打包为单一可执行文件
- `--noconsole`：不显示控制台窗口
- `--add-data`：包含字体等资源（格式：`源路径:目标路径`，Linux下用冒号）

#### 4.1.3 注意事项

- Kivy/KivyMD 打包需确保所有依赖和资源文件正确包含
- 如遇依赖缺失，参考 PyInstaller/Kivy 官方文档调整 `.spec` 文件

---

## 5. 常见问题与解决

- **音频设备找不到**：检查 `portaudio19-dev` 是否安装，或用 `arecord -l` 检查麦克风
- **界面乱码/字体不全**：确保 `assets/fonts/NotoSansSC-VariableFont_wght.ttf` 存在
- **依赖安装慢/失败**：使用国内 PyPI 镜像源
- **API 报错**：检查密钥是否正确、网络是否可访问火山引擎

---

## 6. 参考链接

- [Kivy 官方文档](https://kivy.org/doc/stable/installation/installation-linux.html)
- [KivyMD 官方文档](https://kivymd.readthedocs.io/en/latest/)
- [PyInstaller 官方文档](https://pyinstaller.org/en/stable/)
- [火山引擎 ASR/LLM API 文档](https://www.volcengine.com/docs/)

---

如有问题请联系：manwjh@126.com 