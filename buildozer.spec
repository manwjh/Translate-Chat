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