#!/bin/bash
# =============================================================
# 文件名(File): setup_env.sh
# 版本(Version): v1.0.0
# 作者(Author): 深圳王哥 & AI
# 创建日期(Created): 2025/1/27
# 简介(Description): 跨平台环境变量设置脚本，支持macOS、Linux、Android
# =============================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检测平台
detect_platform() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "android"* ]] || [[ "$OSTYPE" == "linux-android"* ]]; then
        echo "android"
    else
        echo "unknown"
    fi
}

# 获取配置文件路径
get_shell_config_file() {
    local platform=$1
    local shell_type=""
    
    # 检测当前shell
    if [[ -n "$ZSH_VERSION" ]]; then
        shell_type="zsh"
    elif [[ -n "$BASH_VERSION" ]]; then
        shell_type="bash"
    else
        shell_type="bash"
    fi
    
    case $platform in
        "macos")
            if [[ "$shell_type" == "zsh" ]]; then
                echo "$HOME/.zshrc"
            else
                echo "$HOME/.bash_profile"
            fi
            ;;
        "linux")
            if [[ "$shell_type" == "zsh" ]]; then
                echo "$HOME/.zshrc"
            else
                echo "$HOME/.bashrc"
            fi
            ;;
        "android")
            echo "$HOME/.bashrc"
            ;;
        *)
            echo "$HOME/.bashrc"
            ;;
    esac
}

# 显示帮助信息
show_help() {
    echo -e "${BLUE}Translate-Chat 环境变量配置脚本${NC}"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help     显示此帮助信息"
    echo "  -i, --interactive  交互式配置"
    echo "  -c, --check    检查当前配置"
    echo "  -r, --remove   移除环境变量配置"
    echo ""
    echo "示例:"
    echo "  $0 -i          # 交互式配置"
    echo "  $0 -c          # 检查配置"
    echo "  $0 -r          # 移除配置"
    echo ""
}

# 交互式配置
interactive_setup() {
    local platform=$(detect_platform)
    local config_file=$(get_shell_config_file $platform)
    
    echo -e "${BLUE}=== Translate-Chat 环境变量配置 ===${NC}"
    echo -e "检测到平台: ${GREEN}$platform${NC}"
    echo -e "配置文件: ${GREEN}$config_file${NC}"
    echo ""
    
    # 检查是否已配置
    if grep -q "ASR_APP_KEY" "$config_file" 2>/dev/null; then
        echo -e "${YELLOW}警告: 检测到已存在的配置${NC}"
        read -p "是否要覆盖现有配置? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "配置已取消"
            exit 0
        fi
    fi
    
    echo "请输入您的API密钥信息:"
    echo ""
    
    # 获取用户输入
    read -p "ASR_APP_KEY: " asr_app_key
    read -p "ASR_ACCESS_KEY: " asr_access_key
    read -p "LLM_API_KEY: " llm_api_key
    read -p "ASR_APP_ID (可选，回车使用默认值): " asr_app_id
    
    # 验证输入
    if [[ -z "$asr_app_key" || -z "$asr_access_key" || -z "$llm_api_key" ]]; then
        echo -e "${RED}错误: 必要的API密钥不能为空${NC}"
        exit 1
    fi
    
    # 设置默认值
    asr_app_id=${asr_app_id:-"8388344882"}
    
    # 备份原配置文件
    if [[ -f "$config_file" ]]; then
        cp "$config_file" "${config_file}.backup.$(date +%Y%m%d_%H%M%S)"
        echo -e "${GREEN}已备份原配置文件${NC}"
    fi
    
    # 添加配置到文件
    echo "" >> "$config_file"
    echo "# Translate-Chat API配置" >> "$config_file"
    echo "# 添加时间: $(date)" >> "$config_file"
    echo "export ASR_APP_KEY=\"$asr_app_key\"" >> "$config_file"
    echo "export ASR_ACCESS_KEY=\"$asr_access_key\"" >> "$config_file"
    echo "export LLM_API_KEY=\"$llm_api_key\"" >> "$config_file"
    echo "export ASR_APP_ID=\"$asr_app_id\"" >> "$config_file"
    echo "" >> "$config_file"
    
    echo -e "${GREEN}配置已成功添加到 $config_file${NC}"
    echo ""
    echo "请执行以下命令使配置生效:"
    echo -e "${YELLOW}source $config_file${NC}"
    echo ""
    echo "或者重新打开终端"
}

# 检查配置
check_config() {
    local platform=$(detect_platform)
    local config_file=$(get_shell_config_file $platform)
    
    echo -e "${BLUE}=== 配置检查 ===${NC}"
    echo -e "平台: ${GREEN}$platform${NC}"
    echo -e "配置文件: ${GREEN}$config_file${NC}"
    echo ""
    
    # 检查环境变量
    echo "环境变量状态:"
    if [[ -n "$ASR_APP_KEY" ]]; then
        echo -e "  ASR_APP_KEY: ${GREEN}已设置${NC}"
    else
        echo -e "  ASR_APP_KEY: ${RED}未设置${NC}"
    fi
    
    if [[ -n "$ASR_ACCESS_KEY" ]]; then
        echo -e "  ASR_ACCESS_KEY: ${GREEN}已设置${NC}"
    else
        echo -e "  ASR_ACCESS_KEY: ${RED}未设置${NC}"
    fi
    
    if [[ -n "$LLM_API_KEY" ]]; then
        echo -e "  LLM_API_KEY: ${GREEN}已设置${NC}"
    else
        echo -e "  LLM_API_KEY: ${GREEN}已设置${NC}"
    fi
    
    if [[ -n "$ASR_APP_ID" ]]; then
        echo -e "  ASR_APP_ID: ${GREEN}已设置${NC}"
    else
        echo -e "  ASR_APP_ID: ${YELLOW}未设置（使用默认值）${NC}"
    fi
    
    echo ""
    
    # 检查配置文件
    if [[ -f "$config_file" ]]; then
        echo "配置文件状态:"
        if grep -q "ASR_APP_KEY" "$config_file"; then
            echo -e "  ${GREEN}配置文件中包含API配置${NC}"
        else
            echo -e "  ${RED}配置文件中未找到API配置${NC}"
        fi
    else
        echo -e "${RED}配置文件不存在: $config_file${NC}"
    fi
    
    echo ""
}

# 移除配置
remove_config() {
    local platform=$(detect_platform)
    local config_file=$(get_shell_config_file $platform)
    
    echo -e "${BLUE}=== 移除环境变量配置 ===${NC}"
    echo -e "配置文件: ${GREEN}$config_file${NC}"
    echo ""
    
    if [[ ! -f "$config_file" ]]; then
        echo -e "${YELLOW}配置文件不存在${NC}"
        return
    fi
    
    # 备份原文件
    cp "$config_file" "${config_file}.backup.$(date +%Y%m%d_%H%M%S)"
    echo -e "${GREEN}已备份原配置文件${NC}"
    
    # 移除配置行
    sed -i.bak '/# Translate-Chat API配置/,/^$/d' "$config_file"
    rm -f "${config_file}.bak"
    
    echo -e "${GREEN}配置已从 $config_file 中移除${NC}"
    echo ""
    echo "请执行以下命令使更改生效:"
    echo -e "${YELLOW}source $config_file${NC}"
}

# 主函数
main() {
    case "${1:-}" in
        -h|--help)
            show_help
            ;;
        -i|--interactive)
            interactive_setup
            ;;
        -c|--check)
            check_config
            ;;
        -r|--remove)
            remove_config
            ;;
        "")
            show_help
            ;;
        *)
            echo -e "${RED}未知选项: $1${NC}"
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@" 