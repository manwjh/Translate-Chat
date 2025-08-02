#!/usr/bin/env python3
# =============================================================
# 文件名(File): version_manager.py
# 版本(Version): v2.0.3
# 作者(Author): 深圳王哥 & AI
# 创建日期(Created): 2025/7/25
# 最后更新(Updated): 2025/07/29
# 简介(Description): 改进的版本管理脚本 - 支持子模块独立版本和正确日期管理
# =============================================================

"""
改进的版本管理脚本

设计理念:
    - 主项目版本管理整体项目状态
    - 子模块可以有独立版本
    - 创建日期保持不变，只更新更新日期
    - 支持模块化版本管理

功能:
    - 主项目版本管理
    - 子模块独立版本管理
    - 正确的日期管理
    - 版本一致性验证
    - 更新日志生成
    - 项目状态查看
"""

import os
import re
import sys
import argparse
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Tuple

# 项目根目录
PROJECT_ROOT = Path(__file__).parent.parent

# 主项目文件（版本必须与主项目一致）
MAIN_PROJECT_FILES = [
    "main.py",
    "pyproject.toml",
    "__init__.py",
    "requirements.txt",
    "requirements-desktop.txt",
    "translate-chat.spec",
]

# 子模块文件（可以有独立版本）
SUB_MODULE_FILES = {
    "asr_client.py": "语音识别客户端",
    "translator.py": "翻译模块", 
    "config_manager.py": "配置管理",
    "setup_config.py": "配置设置",
    "hotwords.py": "热词检测",
    "lang_detect.py": "语言检测",
    "audio_capture.py": "音频采集",
    "audio_capture_pyaudio.py": "PyAudio音频采集",
    "ui/main_window_kivy.py": "Kivy主窗口",
    "ui/sys_config_window.py": "系统配置窗口",
    "ui/sys_config_window_simple.py": "简化配置窗口",
    "utils/font_utils.py": "字体工具",
    "utils/file_downloader.py": "文件下载器",
    "utils/secure_storage.py": "安全存储",
    "utils/__init__.py": "工具包初始化",
}

# 版本号正则表达式
VERSION_PATTERNS = [
    r'# 版本\(Version\): v(\d+\.\d+\.\d+)',
    r'# Version: v(\d+\.\d+\.\d+)',
    r'version = "(\d+\.\d+\.\d+)"',
    r'__version__ = "(\d+\.\d+\.\d+)"',
    r"APP_VERSION = '(\d+\.\d+\.\d+)'",
    r'APP_VERSION = "(\d+\.\d+\.\d+)"',
]

# 创建日期正则表达式（只读，不修改）
CREATED_DATE_PATTERNS = [
    r'# 创建日期\(Created\): (\d{4}/\d{1,2}/\d{1,2})',
    r'# Created: (\d{4}/\d{1,2}/\d{1,2})',
    r'# 创建日期\(Created\): (\d{4}-\d{1,2}-\d{1,2})',
    r'# Created: (\d{4}-\d{1,2}-\d{1,2})',
]

# 更新日期正则表达式（可修改）
UPDATED_DATE_PATTERNS = [
    r'# 最后更新\(Updated\): (\d{4}/\d{1,2}/\d{1,2})',
    r'# Updated: (\d{4}/\d{1,2}/\d{1,2})',
    r'# 最后更新\(Updated\): (\d{4}-\d{1,2}-\d{1,2})',
    r'# Updated: (\d{4}-\d{1,2}-\d{1,2})',
]

def get_current_date():
    """获取当前日期，格式为 YYYY/MM/DD"""
    return datetime.now().strftime("%Y/%m/%d")

def get_current_datetime():
    """获取当前日期时间，格式为 YYYY/MM/DD HH:MM:SS"""
    return datetime.now().strftime("%Y/%m/%d %H:%M:%S")

def get_main_project_version():
    """获取主项目版本号"""
    init_file = PROJECT_ROOT / "__init__.py"
    if init_file.exists():
        with open(init_file, 'r', encoding='utf-8') as f:
            content = f.read()
            match = re.search(r'__version__ = "(\d+\.\d+\.\d+)"', content)
            if match:
                return match.group(1)
    return "2.0.3"  # 默认版本

def get_file_version(file_path: Path) -> str:
    """获取单个文件的版本号"""
    if not file_path.exists():
        return "0.0.0"
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    for pattern in VERSION_PATTERNS:
        match = re.search(pattern, content)
        if match:
            return match.group(1)
    
    return "0.0.0"

def get_file_dates(file_path: Path) -> Tuple[str, str]:
    """获取文件的创建日期和更新日期"""
    if not file_path.exists():
        return "", ""
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    created_date = ""
    updated_date = ""
    
    # 查找创建日期
    for pattern in CREATED_DATE_PATTERNS:
        match = re.search(pattern, content)
        if match:
            created_date = match.group(1)
            break
    
    # 查找更新日期
    for pattern in UPDATED_DATE_PATTERNS:
        match = re.search(pattern, content)
        if match:
            updated_date = match.group(1)
            break
    
    return created_date, updated_date

def update_file_version_and_date(file_path: Path, new_version: str, update_date: bool = False) -> bool:
    """更新单个文件的版本号和更新日期"""
    if not file_path.exists():
        print(f"警告: 文件不存在 {file_path}")
        return False
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    current_date = get_current_date()
    
    # 更新版本号
    for pattern in VERSION_PATTERNS:
        content = re.sub(pattern, lambda m: m.group(0).replace(m.group(1), new_version), content)
    
    # 特殊处理pyproject.toml
    if file_path.name == "pyproject.toml":
        content = re.sub(r'version = "(\d+\.\d+\.\d+)"', f'version = "{new_version}"', content)
    
    # 特殊处理translate-chat.spec
    if file_path.name == "translate-chat.spec":
        content = re.sub(r"APP_VERSION = '(\d+\.\d+\.\d+)'", f"APP_VERSION = '{new_version}'", content)
        content = re.sub(r'APP_VERSION = "(\d+\.\d+\.\d+)"', f'APP_VERSION = "{new_version}"', content)
    
    # 更新更新日期（如果需要）
    if update_date:
        # 查找并更新更新日期
        date_updated = False
        for pattern in UPDATED_DATE_PATTERNS:
            if re.search(pattern, content):
                content = re.sub(pattern, lambda m: m.group(0).replace(m.group(1), current_date), content)
                date_updated = True
                break
        
        # 如果没有找到更新日期字段，尝试添加
        if not date_updated:
            # 在版本行后添加更新日期
            for pattern in VERSION_PATTERNS:
                if re.search(pattern, content):
                    content = re.sub(pattern, lambda m: m.group(0) + f'\n# 最后更新(Updated): {current_date}', content)
                    break
    
    if content != original_content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"✅ 已更新: {file_path}")
        return True
    else:
        print(f"⚠️  无需更新: {file_path}")
        return False

def update_main_project_version(new_version: str, update_date: bool = False) -> int:
    """更新主项目文件版本"""
    print(f"🔄 更新主项目版本: {get_main_project_version()} -> {new_version}")
    print("-" * 50)
    
    updated_count = 0
    for file_path in MAIN_PROJECT_FILES:
        full_path = PROJECT_ROOT / file_path
        if update_file_version_and_date(full_path, new_version, update_date):
            updated_count += 1
    
    print("-" * 50)
    print(f"主项目文件更新完成: {updated_count} 个文件")
    return updated_count

def update_sub_module_version(module_file: str, new_version: str, update_date: bool = False) -> bool:
    """更新子模块版本"""
    file_path = PROJECT_ROOT / module_file
    if not file_path.exists():
        print(f"警告: 子模块文件不存在 {file_path}")
        return False
    
    module_name = SUB_MODULE_FILES.get(module_file, module_file)
    print(f"🔄 更新子模块 {module_name}: {get_file_version(file_path)} -> {new_version}")
    
    return update_file_version_and_date(file_path, new_version, update_date)

def show_project_status():
    """显示项目状态信息"""
    main_version = get_main_project_version()
    current_date = get_current_date()
    current_datetime = get_current_datetime()
    
    print("=" * 60)
    print("📊 项目版本状态")
    print("=" * 60)
    print(f"主项目版本: {main_version}")
    print(f"当前日期: {current_date}")
    print(f"当前时间: {current_datetime}")
    print(f"项目根目录: {PROJECT_ROOT}")
    print()
    
    print("📁 主项目文件:")
    for file_path in MAIN_PROJECT_FILES:
        full_path = PROJECT_ROOT / file_path
        if full_path.exists():
            version = get_file_version(full_path)
            created_date, updated_date = get_file_dates(full_path)
            status = "✅" if version == main_version else "❌"
            print(f"  {status} {file_path}: v{version}")
            if created_date:
                print(f"     创建: {created_date}")
            if updated_date:
                print(f"     更新: {updated_date}")
        else:
            print(f"  ⚠️  {file_path}: 文件不存在")
    
    print()
    print("🔧 子模块文件:")
    for file_path, description in SUB_MODULE_FILES.items():
        full_path = PROJECT_ROOT / file_path
        if full_path.exists():
            version = get_file_version(full_path)
            created_date, updated_date = get_file_dates(full_path)
            print(f"  📄 {file_path} ({description}): v{version}")
            if created_date:
                print(f"     创建: {created_date}")
            if updated_date:
                print(f"     更新: {updated_date}")
        else:
            print(f"  ⚠️  {file_path}: 文件不存在")
    
    print("=" * 60)

def validate_main_project_consistency() -> bool:
    """验证主项目文件版本一致性"""
    main_version = get_main_project_version()
    print(f"🔍 验证主项目版本一致性 (版本: {main_version})")
    print("-" * 50)
    
    inconsistent_files = []
    for file_path in MAIN_PROJECT_FILES:
        full_path = PROJECT_ROOT / file_path
        if not full_path.exists():
            continue
        
        version = get_file_version(full_path)
        if version != main_version:
            inconsistent_files.append((file_path, version))
            print(f"❌ 版本不一致: {file_path} (v{version} != v{main_version})")
        else:
            print(f"✅ 版本一致: {file_path}")
    
    print("-" * 50)
    if inconsistent_files:
        print(f"发现 {len(inconsistent_files)} 个版本不一致的主项目文件")
        return False
    else:
        print("所有主项目文件版本一致 ✅")
        return True

def generate_changelog_entry(new_version: str, changes: List[str], module_updates: Dict[str, str] = None):
    """生成更新日志条目"""
    current_date = get_current_date()
    
    changelog_entry = f"""## v{new_version} ({current_date}) - 版本更新

### 🔧 版本管理改进
- **主项目版本**: 升级到 v{new_version}
- **模块化版本管理**: 支持子模块独立版本
- **日期管理优化**: 区分创建日期和更新日期

"""
    
    if module_updates:
        changelog_entry += "### 📦 子模块更新\n"
        for module, version in module_updates.items():
            changelog_entry += f"- **{module}**: v{version}\n"
        changelog_entry += "\n"
    
    changelog_entry += "### 📝 更新内容\n"
    for change in changes:
        changelog_entry += f"- {change}\n"
    
    changelog_entry += "\n---\n\n"
    
    return changelog_entry

def update_changelog(new_version: str, changes: List[str], module_updates: Dict[str, str] = None):
    """更新CHANGELOG.md"""
    changelog_file = PROJECT_ROOT / "CHANGELOG.md"
    if not changelog_file.exists():
        print("警告: CHANGELOG.md 不存在")
        return
    
    with open(changelog_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    changelog_entry = generate_changelog_entry(new_version, changes, module_updates)
    
    # 在第一个版本条目前插入新条目
    lines = content.split('\n')
    insert_pos = 0
    for i, line in enumerate(lines):
        if line.startswith('## v') and '更新日志' not in line:
            insert_pos = i
            break
    
    lines.insert(insert_pos, changelog_entry)
    
    with open(changelog_file, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines))
    
    print(f"✅ 已更新 CHANGELOG.md")

def main():
    parser = argparse.ArgumentParser(description="改进的版本管理脚本")
    parser.add_argument("action", choices=["status", "validate", "bump", "update", "module"], 
                       help="执行的操作")
    parser.add_argument("--version", "-v", help="新版本号 (格式: x.y.z)")
    parser.add_argument("--changes", "-c", nargs="+", 
                       help="更新内容描述")
    parser.add_argument("--update-date", "-d", action="store_true",
                       help="同时更新文件更新日期")
    parser.add_argument("--module", "-m", help="指定子模块文件")
    
    args = parser.parse_args()
    
    if args.action == "status":
        show_project_status()
        return
    
    elif args.action == "validate":
        success = validate_main_project_consistency()
        sys.exit(0 if success else 1)
    
    elif args.action == "bump":
        current = get_main_project_version()
        major, minor, patch = map(int, current.split('.'))
        
        if not args.version:
            # 默认增加补丁版本
            new_version = f"{major}.{minor}.{patch + 1}"
        else:
            new_version = args.version
        
        print(f"🔄 主项目版本升级: {current} -> {new_version}")
        update_main_project_version(new_version, args.update_date)
        
        if args.changes:
            update_changelog(new_version, args.changes)
    
    elif args.action == "update":
        if not args.version:
            print("错误: 更新版本需要指定 --version 参数")
            sys.exit(1)
        
        if not re.match(r'^\d+\.\d+\.\d+$', args.version):
            print("错误: 版本号格式应为 x.y.z")
            sys.exit(1)
        
        update_main_project_version(args.version, args.update_date)
        
        if args.changes:
            update_changelog(args.version, args.changes)
    
    elif args.action == "module":
        if not args.module:
            print("错误: 子模块操作需要指定 --module 参数")
            sys.exit(1)
        
        if not args.version:
            print("错误: 子模块更新需要指定 --version 参数")
            sys.exit(1)
        
        if args.module not in SUB_MODULE_FILES:
            print(f"错误: 未知的子模块 {args.module}")
            print(f"可用的子模块: {list(SUB_MODULE_FILES.keys())}")
            sys.exit(1)
        
        update_sub_module_version(args.module, args.version, args.update_date)
        
        if args.changes:
            module_updates = {args.module: args.version}
            update_changelog(get_main_project_version(), args.changes, module_updates)

if __name__ == "__main__":
    main() 