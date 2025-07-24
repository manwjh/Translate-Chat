#!/bin/bash
cd "$(dirname "$0")"

# 杀死当前目录下的 main.py 进程（避免误杀其他同名脚本）
PROJECT_DIR="$(pwd)"
ps -eo pid,comm,args | grep '[p]ython' | grep 'main.py' | while read pid comm args; do
    # 检查进程的工作目录
    PROC_CWD=$(lsof -p $pid 2>/dev/null | awk '$4=="cwd" {print $9}')
    if [ "$PROC_CWD" = "$PROJECT_DIR" ]; then
        echo "杀死残留 main.py 进程: $pid ($args)"
        kill -9 $pid
    fi
done

# 检查并创建虚拟环境，只在首次创建时安装依赖
if [ ! -d "venv" ]; then
    echo "未检测到虚拟环境，正在创建..."
    python3 -m venv venv
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
else
    source venv/bin/activate
fi

# 设置 Qt 插件路径
export QT_QPA_PLATFORM_PLUGIN_PATH=$(python -c "import PyQt6.QtCore, os; print(os.path.dirname(PyQt6.QtCore.__file__) + '/plugins')")

# 运行主程序
python main.py 