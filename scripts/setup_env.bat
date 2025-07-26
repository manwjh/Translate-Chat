@echo off
REM =============================================================
REM 文件名(File): setup_env.bat
REM 版本(Version): v1.0.0
REM 作者(Author): 深圳王哥 & AI
REM 创建日期(Created): 2025/1/27
REM 简介(Description): Windows环境变量设置脚本
REM =============================================================

setlocal enabledelayedexpansion

:main
echo ========================================
echo    Translate-Chat 环境变量配置脚本
echo ========================================
echo.

if "%1"=="-h" goto help
if "%1"=="--help" goto help
if "%1"=="-i" goto interactive
if "%1"=="--interactive" goto interactive
if "%1"=="-c" goto check
if "%1"=="--check" goto check
if "%1"=="" goto help

echo 未知选项: %1
goto help

:help
echo 用法: %0 [选项]
echo.
echo 选项:
echo   -h, --help     显示此帮助信息
echo   -i, --interactive  交互式配置
echo   -c, --check    检查当前配置
echo.
echo 示例:
echo   %0 -i          # 交互式配置
echo   %0 -c          # 检查配置
echo.
goto end

:interactive
echo === Translate-Chat 环境变量配置 ===
echo 检测到平台: Windows
echo.

echo 请输入您的API密钥信息:
echo.

set /p asr_app_key="ASR_APP_KEY: "
set /p asr_access_key="ASR_ACCESS_KEY: "
set /p llm_api_key="LLM_API_KEY: "
set /p asr_app_id="ASR_APP_ID (可选，回车使用默认值): "

if "%asr_app_key%"=="" (
    echo 错误: ASR_APP_KEY 不能为空
    goto end
)
if "%asr_access_key%"=="" (
    echo 错误: ASR_ACCESS_KEY 不能为空
    goto end
)
if "%llm_api_key%"=="" (
    echo 错误: LLM_API_KEY 不能为空
    goto end
)

if "%asr_app_id%"=="" set asr_app_id=8388344882

echo.
echo 正在设置环境变量...

REM 设置用户环境变量
setx ASR_APP_KEY "%asr_app_key%"
setx ASR_ACCESS_KEY "%asr_access_key%"
setx LLM_API_KEY "%llm_api_key%"
setx ASR_APP_ID "%asr_app_id%"

echo.
echo 配置已成功设置！
echo 请重新打开命令提示符或PowerShell以使配置生效。
echo.
goto end

:check
echo === 配置检查 ===
echo 平台: Windows
echo.

echo 环境变量状态:
if defined ASR_APP_KEY (
    echo   ASR_APP_KEY: 已设置
) else (
    echo   ASR_APP_KEY: 未设置
)

if defined ASR_ACCESS_KEY (
    echo   ASR_ACCESS_KEY: 已设置
) else (
    echo   ASR_ACCESS_KEY: 未设置
)

if defined LLM_API_KEY (
    echo   LLM_API_KEY: 已设置
) else (
    echo   LLM_API_KEY: 未设置
)

if defined ASR_APP_ID (
    echo   ASR_APP_ID: 已设置
) else (
    echo   ASR_APP_ID: 未设置（使用默认值）
)

echo.
echo 注意: 在Windows中，环境变量需要重新启动命令提示符才能生效。
echo.

:end
pause 