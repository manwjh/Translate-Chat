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
android.sdk = 33
android.arch = arm64-v8a

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

# 网络配置（如果需要）
android.enable_androidx = True

# 日志配置
log_level = 2

# SDL2 本地文件配置 - 优先使用本地文件避免网络下载
# 将本地文件放在 /tmp 目录下，文件名格式: SDL2_mixer-2.6.3.tar

# SDL2 本地文件路径配置
# 如果本地文件存在，buildozer 会优先使用本地文件
# 支持的本地文件:
# - /tmp/SDL2-2.28.5.tar
# - /tmp/SDL2_image-2.8.0.tar  
# - /tmp/SDL2_mixer-2.6.3.tar
# - /tmp/SDL2_ttf-2.20.2.tar

# 设置SDL2本地文件路径环境变量
# 这些环境变量会在构建过程中传递给buildozer
# 确保SDL2相关包优先使用本地文件 