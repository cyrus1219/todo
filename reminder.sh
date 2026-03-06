#!/bin/bash

# 待办事项提醒脚本
# 用于定时推送待办事项和询问完成情况

TODO_DIR="/root/.openclaw/workspace/todo"
TODO_FILE="$TODO_DIR/todos.json"
TODO_SCRIPT="$TODO_DIR/todo.sh"

cd "$TODO_DIR" || exit 1

# 加载待办事项
load_todos() {
    if [ -f "$TODO_FILE" ]; then
        cat "$TODO_FILE"
    else
        echo '{"todos": []}'
    fi
}

# 格式化早上提醒
format_morning_reminder() {
    local todos=$(load_todos)
    
    python3 -c "
import json
from datetime import datetime, timedelta

data = json.loads('''$todos''')
todos = data.get('todos', [])

high = [t for t in todos if t['priority'] == 'high' and not t['completed']]
medium = [t for t in todos if t['priority'] == 'medium' and not t['completed']]
low = [t for t in todos if t['priority'] == 'low' and not t['completed']]
completed = [t for t in todos if t['completed']]

print('🌅 早上好！这是你今天的待办事项清单')
print('=' * 60)

if high:
    print('\n🔴 【高优先级】')
    for i, t in enumerate(high, 1):
        due = t.get('dueDate', '无截止时间')
        print(f'  {i}. {t[\"text\"]} (截止: {due})')

if medium:
    print('\n🟡 【中优先级】')
    for i, t in enumerate(medium, 1):
        due = t.get('dueDate', '无截止时间')
        print(f'  {i}. {t[\"text\"]} (截止: {due})')

if low:
    print('\n🟢 【低优先级】')
    for i, t in enumerate(low, 1):
        due = t.get('dueDate', '无截止时间')
        print(f'  {i}. {t[\"text\"]} (截止: {due})')

total_pending = len(high) + len(medium) + len(low)
print(f'\n📊 统计：待完成 {total_pending} 项，已完成 {len(completed)} 项')
print('=' * 60)
print('\n祝你今天工作顺利！💪')
"
}

# 格式化晚上询问
format_evening_checkin() {
    local todos=$(load_todos)
    
    python3 -c "
import json
from datetime import datetime, timedelta

data = json.loads('''$todos''')
todos = data.get('todos', [])

high = [t for t in todos if t['priority'] == 'high' and not t['completed']]
medium = [t for t in todos if t['priority'] == 'medium' and not t['completed']]
low = [t for t in todos if t['priority'] == 'low' and not t['completed']]
completed = [t for t in todos if t['completed']]

print('🌆 晚上好！来回顾一下今天的待办事项 👋')
print('=' * 60)

if completed:
    print('\n✅ 【已完成】')
    for i, t in enumerate(completed, 1):
        due = t.get('dueDate', '无截止时间')
        print(f'  {i}. {t[\"text\"]} (截止: {due})')

if high:
    print('\n🔴 【还未完成 - 高优先级】')
    for i, t in enumerate(high, 1):
        due = t.get('dueDate', '无截止时间')
        print(f'  {i}. {t[\"text\"]} (截止: {due})')

if medium:
    print('\n🟡 【还未完成 - 中优先级】')
    for i, t in enumerate(medium, 1):
        due = t.get('dueDate', '无截止时间')
        print(f'  {i}. {t[\"text\"]} (截止: {due})')

if low:
    print('\n🟢 【还未完成 - 低优先级】')
    for i, t in enumerate(low, 1):
        due = t.get('dueDate', '无截止时间')
        print(f'  {i}. {t[\"text\"]} (截止: {due})')

print(f'\n📊 统计：已完成 {len(completed)} 项，待完成 {len(high) + len(medium) + len(low)} 项')
print('=' * 60)
print('\n告诉我：')
print('• 哪些已经完成了？（说完成第X项）')
print('• 哪些需要调整优先级或截止时间？')
print('• 明天有什么新的待办事项要添加吗？')
"
}

# 提交到 GitHub
commit_and_push() {
    local message="${1:-更新待办事项}"
    
    cd "$TODO_DIR" || exit 1
    
    git add .
    if git diff --cached --quiet; then
        echo "没有变化需要提交"
        return 0
    fi
    
    git commit -m "$message"
    git push origin main
    echo "已推送到 GitHub"
}

# 主命令
case "$1" in
    morning)
        format_morning_reminder
        ;;
    evening)
        format_evening_checkin
        ;;
    push)
        shift
        commit_and_push "$@"
        ;;
    *)
        echo "用法: $0 {morning|evening|push}"
        exit 1
        ;;
esac
