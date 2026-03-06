# ToDo List

一个简单的待办事项管理系统，支持网页端和每日提醒。

## 功能特性

- 📱 响应式设计，适配手机和电脑
- 🎨 简洁美观的界面
- 📊 优先级管理（高/中/低）
- ✅ 任务完成状态跟踪
- 🔔 每日定时提醒
- 📄 JSON 数据格式，易于备份

## 使用方法

1. 打开 `index.html` 即可使用
2. 数据存储在 `todos.json` 文件中
3. 可以通过 GitHub Pages 托管

## 数据格式

```json
{
  "todos": [
    {
      "id": "1",
      "text": "待办事项内容",
      "priority": "high",
      "completed": false,
      "createdAt": "2024-01-01T00:00:00.000Z"
    }
  ]
}
```
