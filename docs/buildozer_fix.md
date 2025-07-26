# Buildozer 故障排除指南

## 常见错误及解决方案

### 1. 配置弃用错误

**错误信息：**
```
# `android.archs` not detected, instead `android.arch` is present.
# `android.arch` will be removed and ignored in future.
# WARNING: Config token app android.sdk is deprecated and ignored
```

**解决方案：**
运行修复脚本：
```bash
./scripts/fix_buildozer.sh
```

或者手动修改 `buildozer.spec`：
- 将 `android.arch = arm64-v8a` 改为 `android.archs = arm64-v8a, armeabi-v7a`
- 删除 `android.sdk = 33` 行

### 2. 路径错误

**错误信息：**
```
FileNotFoundError: [Errno 2] No such file or directory: '.../python-for-android'
```

**解决方案：**
清理构建缓存：
```bash
rm -rf .buildozer
```

### 3. 权限错误

**解决方案：**
```bash
sudo chown -R $USER:$USER .
chmod -R 755 .
```

## 快速诊断

运行诊断脚本检查环境：
```bash
./scripts/diagnose_buildozer.sh
```

## 完整修复流程

1. 运行诊断脚本：
   ```bash
   ./scripts/diagnose_buildozer.sh
   ```

2. 运行修复脚本：
   ```bash
   ./scripts/fix_buildozer.sh
   ```

3. 重新构建：
   ```bash
   ./scripts/build_android_ubuntu.sh
   ```

## 注意事项

- 确保在项目根目录运行脚本
- 确保已安装必要的系统依赖
- 首次构建可能需要较长时间下载SDK/NDK 