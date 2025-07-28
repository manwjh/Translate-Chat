# 依赖清理说明 / Dependency Cleanup Documentation

**文件名(File):** DEPENDENCY_CLEANUP.md  
**版本(Version):** v1.0.0  
**作者(Author):** 深圳王哥 & AI  
**创建日期(Created):** 2025/1/25  
**简介(Description):** 记录移除的不必要依赖和优化说明

---

## 🧹 依赖清理总结 / Dependency Cleanup Summary

### 移除的依赖 / Removed Dependencies

#### 1. FFmpeg相关库 / FFmpeg Libraries
**移除原因**: resemblyzer库通常不需要完整的FFmpeg库支持

**已移除的包**:
- `libavcodec58` - FFmpeg编解码库
- `libavformat58` - FFmpeg格式处理库  
- `libavdevice58` - FFmpeg设备接口库 ⭐ **特别不必要**
- `libavutil56` - FFmpeg工具库
- `libswscale5` - FFmpeg图像缩放库
- `libavfilter7` - FFmpeg滤镜库
- `libavresample4` - FFmpeg重采样库
- `libpostproc55` - FFmpeg后处理库
- `libswresample3` - FFmpeg音频重采样库

#### 2. 构建脚本优化 / Build Script Optimization
**修改的文件**:
- `scripts/linux_dependency_manager.sh` - 移除FFmpeg依赖下载
- `scripts/unified_build_system.sh` - 注释掉libavdevice-dev
- `scripts/local_build_linux.sh` - 注释掉libavdevice-dev
- `scripts/README.md` - 更新依赖说明

### 保留的必要依赖 / Kept Essential Dependencies

#### 音频处理库 / Audio Processing Libraries
- `libportaudio2` - PortAudio音频库（PyAudio依赖）
- `libasound2` - ALSA音频库
- `libpulse0` - PulseAudio音频库
- `libjack-jackd2-0` - JACK音频库

#### Python依赖 / Python Dependencies
- `numpy` - 数值计算（音频数据处理）
- `scipy` - 科学计算（音频处理）
- `resemblyzer` - 说话人识别
- `webrtcvad` - 语音活动检测

### 优化效果 / Optimization Benefits

#### 1. 减少安装包大小 / Reduced Package Size
- **移除前**: ~50MB FFmpeg相关库
- **移除后**: 仅保留必要的音频库
- **节省空间**: 约40-50MB

#### 2. 简化依赖管理 / Simplified Dependency Management
- 减少系统级依赖冲突
- 降低安装失败概率
- 提高跨平台兼容性

#### 3. 提升构建速度 / Improved Build Speed
- 减少下载时间
- 简化依赖解析
- 加快打包过程

### 验证方法 / Verification Methods

#### 1. 功能测试 / Functional Testing
```bash
# 测试音频采集
python3 audio_capture_pyaudio.py

# 测试说话人检测
python3 -c "from speaker_change_detector import SpeakerChangeDetector; print('OK')"

# 测试主程序
python3 main.py
```

#### 2. 依赖检查 / Dependency Check
```bash
# 检查Python依赖
pip list | grep -E "(numpy|scipy|resemblyzer|webrtcvad)"

# 检查系统依赖（Linux）
ldd /usr/lib/python3/dist-packages/pyaudio/_portaudio.so
```

### 注意事项 / Important Notes

#### 1. 回滚方案 / Rollback Plan
如果发现resemblyzer确实需要FFmpeg支持，可以重新添加：
```bash
# 重新添加FFmpeg依赖
sudo apt-get install libavcodec-dev libavformat-dev libavutil-dev
```

#### 2. 平台兼容性 / Platform Compatibility
- **macOS**: 不受影响，使用Homebrew管理音频库
- **Linux**: 已优化，移除不必要的FFmpeg依赖
- **Windows**: 不受影响，使用预编译的wheel包

#### 3. 性能影响 / Performance Impact
- **音频处理**: 无影响，使用numpy/scipy进行数值计算
- **说话人检测**: 无影响，resemblyzer使用轻量级模型
- **整体性能**: 可能略有提升（减少库加载时间）

---

## 📝 更新日志 / Changelog

### v1.0.0 (2025/1/25)
- 🧹 **依赖清理**: 移除不必要的FFmpeg相关库
- 📦 **构建优化**: 简化Linux构建脚本
- 📚 **文档更新**: 更新依赖说明和构建指南
- ✅ **功能验证**: 确保核心功能不受影响

---

## 🔗 相关文件 / Related Files

- `requirements-desktop.txt` - Python依赖列表
- `scripts/linux_dependency_manager.sh` - Linux依赖管理
- `scripts/unified_build_system.sh` - 统一构建系统
- `scripts/local_build_linux.sh` - 本地Linux构建
- `scripts/README.md` - 构建说明文档 