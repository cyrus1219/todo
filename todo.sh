#!/bin/bash

# ToDo List 管理脚本
# 用于管理待办事项和自动提交到 GitHub

TODO_DIR="/root/.openclaw/workspace/todo"
TODO_FILE="$TODO_DIR/todos.json"
cd "$TODO_DIR" || exit 1

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 加载待办事项
load_todos() {
    if [ -f "$TODO_FILE" ]; then
        cat "$TODO_FILE"
    else
        echo '{"todos": []}'
    fi
}

# 保存待办事项
save_todos() {
    local content="$1"
    echo "$content" > "$TODO_FILE"
    echo -e "${GREEN}✅ 待办事项已保存${NC}"
}

# 添加待办事项
add_todo() {
    local text="$1"
    local priority="${2:-medium}"
    
    if [ -z "$text" ]; then
        echo -e "${RED}❌ 请提供待办事项内容${NC}"
        return 1
    fi
    
    local todos=$(load_todos)
    local id=$(date +%s)
    local now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    local new_todo=$(cat <<EOF
{
  "id": "$id",
  "text": "$text",
  "priority": "$priority",
  "completed": false,
  "createdAt": "$now"
}
EOF
)
    
    # 使用 Python 来处理 JSON
    local updated=$(python3 -c "
import json
import sys
data = json.loads('''$todos''')
new_todo = json.loads('''$new_todo''')
data['todos'].insert(0, new_todo)
print(json.dumps(data, ensure_ascii=False, indent=2))
")
    
    save_todos "$updated"
    echo -e "${GREEN}✅ 已添加待办事项: $text${NC}"
}

# 列出待办事项
list_todos() {
    local todos=$(load_todos)
    
    python3 -c "
import json
data = json.loads('''$todos''')
todos = data.get('todos', [])

if not todos:
    print('📭 没有待办事项')
else:
    priority_emoji = {'high': '🔴', 'medium': '🟡', 'low': '🟢'}
    priority_name = {'high': '高', 'medium': '中', 'low': '低'}
    
    print('\n📋 待办事项列表:\n')
    
    for i, todo in enumerate(todos, 1):
        status = '✅' if todo['completed'] else '⬜'
        emoji = priority_emoji.get(todo['priority'], '⚪')
        p_name = priority_name.get(todo['priority'], '未知')
        print(f'{i}. {status} {emoji} [{p_name}] {todo[\"text\"]}')
    
    print(f'\n总计: {len(todos)} 项')
"
}

# 标记完成
complete_todo() {
    local index="$1"
    
    if [ -z "$index" ]; then
        echo -e "${RED}❌ 请提供待办事项序号${NC}"
        return 1
    fi
    
    local todos=$(load_todos)
    
    local updated=$(python3 -c "
import json
data = json.loads('''$todos''')
idx = int('$index') - 1
if 0 <= idx < len(data['todos']):
    data['todos'][idx]['completed'] = True
    print(json.dumps(data, ensure_ascii=False, indent=2))
else:
    print('ERROR: 无效的序号')
")
    
    if [[ "$updated" == ERROR* ]]; then
        echo -e "${RED}❌ ${updated#ERROR: }${NC}"
        return 1
    fi
    
    save_todos "$updated"
    echo -e "${GREEN}✅ 已标记为完成${NC}"
}

# 删除待办
delete_todo() {
    local index="$1"
    
    if [ -z "$index" ]; then
        echo -e "${RED}❌ 请提供待办事项序号${NC}"
        return 1
    fi
    
    local todos=$(load_todos)
    
    local updated=$(python3 -c "
import json
data = json.loads('''$todos''')
idx = int('$index') - 1
if 0 <= idx < len(data['todos']):
    deleted = data['todos'].pop(idx)
    print(json.dumps(data, ensure_ascii=False, indent=2))
else:
    print('ERROR: 无效的序号')
")
    
    if [[ "$updated" == ERROR* ]]; then
        echo -e "${RED}❌ ${updated#ERROR: }${NC}"
        return 1
    fi
    
    save_todos "$updated"
    echo -e "${GREEN}✅ 已删除待办事项${NC}"
}

# 提交到 GitHub
commit_to_github() {
    local message="${1:-更新待办事项}"
    
    cd "$TODO_DIR" || exit 1
    
    git add .
    if git diff --cached --quiet; then
        echo -e "${YELLOW}⚠️  没有变化需要提交${NC}"
        return 0
    fi
    
    git commit -m "$message"
    echo -e "${GREEN}✅ 已提交到本地仓库${NC}"
    
    if git remote -v 2>/dev/null | grep -q origin; then
        git push origin main 2>/dev/null || git push origin master 2>/dev/null
        echo -e "${GREEN}✅ 已推送到 GitHub${NC}"
    else
        echo -e "${YELLOW}⚠️  未配置远程仓库，请先设置 GitHub 远程地址${NC}"
    fi
}

# 格式化待办事项用于推送
format_todos_for_push() {
    local todos=$(load_todos)
    
    python3 -c "
import json
from datetime import datetime

data = json.loads('''$todos''')
todos = data.get('todos', [])

high = [t for t in todos if t['priority'] == 'high' and not t['completed']]
medium = [t for t in todos if t['priority'] == 'medium' and not t['completed']]
low = [t for t in todos if t['priority'] == 'low' and not t['completed']]
completed = [t for t in todos if t['completed']]

print('📋 待办事项清单')
print('=' * 50)

if high:
    print('\n🔴 高优先级:')
    for i, t in enumerate(high, 1):
        print(f'  {i}. {t[\"text\"]}')

if medium:
    print('\n🟡 中优先级:')
    for i, t in enumerate(medium, 1):
        print(f'  {i}. {t[\"text\"]}')

if low:
    print('\n🟢 低优先级:')
    for i, t in enumerate(low, 1):
        print(f'  {i}. {t[\"text\"]}')

print(f'\n✅ 已完成: {len(completed)} 项')
print('=' * 50)
"
}

# 主菜单
show_help() {
    echo "
📋 ToDo List 管理工具

用法:
  $0 add <内容> [优先级]  - 添加待办事项 (优先级: high/medium/low)
  $0 list                  - 列出所有待办事项
  $0 complete <序号>        - 标记待办事项为完成
  $0 delete <序号>          - 删除待办事项
  $0 push [消息]            - 提交并推送到 GitHub
  $0 format                 - 格式化输出待办事项
  $0 help                   - 显示帮助

示例:
  $0 add \"完成项目报告\" high
  $0 list
  $0 complete 1
  $0 push \"更新待办事项\"
"
}

# 解析命令
case "${1:-help}" in
    add)
        shift
        add_todo "$@"
        ;;
    list)
        list_todos
        ;;
    complete)
        shift
        complete_todo "$1"
        ;;
    delete)
        shift
        delete_todo "$1"
        ;;
    push)
        shift
        commit_to_github "$@"
        ;;
    format)
        format_todos_for_push
        ;;
    help|*)
        show_help
        ;;
esac
