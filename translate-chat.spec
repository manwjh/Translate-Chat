# -*- mode: python ; coding: utf-8 -*-


a = Analysis(
    ['main.py'],
    pathex=[],
    binaries=[],
    datas=[('assets', 'assets'), ('ui', 'ui'), ('utils', 'utils')],
    hiddenimports=['kivy', 'kivymd', 'websocket', 'aiohttp', 'cryptography', 'pyaudio', 'asr_client', 'translator', 'config_manager', 'lang_detect', 'hotwords', 'audio_capture', 'audio_capture_pyaudio'],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    noarchive=False,
    optimize=0,
)
pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.datas,
    [],
    name='translate-chat',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)
app = BUNDLE(
    exe,
    name='translate-chat.app',
    icon=None,
    bundle_identifier=None,
)
