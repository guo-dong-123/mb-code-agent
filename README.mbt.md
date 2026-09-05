# mb-code-agent

基于 MoonBit 实现的终端代码智能体。输入自然语言需求，自动生成 MoonBit 代码并在本地沙箱中执行，支持工具调用、多轮自动纠错、交互式 REPL 和代码智能分析。

## ✨ 核心特性

- **🤖 Tool Use 工具调用** — 大模型可主动调用工具探索环境：读取本地文件、执行 Shell 命令、查询系统时间，基于真实信息生成代码
- **🧪 本地沙箱执行** — 生成的代码写入临时 MoonBit 项目，调用 `moon run` 执行，捕获输出和报错
- **🔄 多轮自动纠错** — 执行失败时，自动将报错信息喂回大模型修复，最多重试 3 轮
- **💬 交互式 REPL** — 无参数启动进入对话模式，连续输入需求，支持 /help、/clear、/exit 命令
- **📝 代码智能分析** — 执行成功后，自动生成中文代码逻辑解释 + 优化建议（性能、可读性、规范）
- **🎨 彩色终端输出** — ANSI 颜色高亮，成功/失败/信息分色显示，代码块带标记
- **🔒 安全沙箱** — 10 秒执行超时、输出长度截断、临时目录自动清理、危险命令黑名单拦截
- **🌐 OpenAI 兼容接口** — 支持任意 OpenAI 兼容的大模型 API（默认通义千问 DashScope）
- **⚙️ 环境变量配置** — API Key、Base URL、模型名通过环境变量配置，不硬编码

## 🛠️ 内置工具

| 工具名 | 功能 |
|--------|------|
| `read_file` | 读取本地文件内容 |
| `execute_command` | 执行 Shell 命令（危险命令自动拦截） |
| `get_current_time` | 获取当前系统日期时间 |

## 📦 安装

### 前置要求

- [MoonBit 工具链](https://www.moonbitlang.com/download)（moon 0.1.20260827+）
- 一个 OpenAI 兼容的大模型 API Key

### 安装 MoonBit

```bash
curl -fsSL https://cli.moonbitlang.cn/install/unix.sh | bash
source ~/.zshrc
moon version
```

### 克隆项目

```bash
git clone https://github.com/guo-dong-123/mb-code-agent.git
cd mb-code-agent
```

## ⚙️ 配置

设置环境变量：

```bash
# 必填：API Key
export MB_AGENT_API_KEY="sk-your-api-key"

# 可选：API Base URL（默认通义千问 DashScope 兼容模式）
export MB_AGENT_BASE_URL="https://dashscope.aliyuncs.com/compatible-mode/v1"

# 可选：模型名称（默认 qwen3.8-max）
export MB_AGENT_MODEL="qwen3.8-max"
```

支持其他 OpenAI 兼容接口：

```bash
# OpenAI
export MB_AGENT_BASE_URL="https://api.openai.com/v1"
export MB_AGENT_MODEL="gpt-4o-mini"

# DeepSeek
export MB_AGENT_BASE_URL="https://api.deepseek.com/v1"
export MB_AGENT_MODEL="deepseek-chat"
```

## 🚀 使用方法

### 单次执行模式

```bash
moon run cmd/main "你的需求描述"
```

### 交互式 REPL 模式

```bash
moon run cmd/main
```

进入交互模式后：
- 直接输入需求，自动生成并执行代码
- `/help` — 查看帮助
- `/clear` — 清屏
- `/exit` — 退出

### 示例

```bash
# 计算斐波那契数列
moon run cmd/main "写一个计算斐波那契数列第10项的程序"

# 快速排序
moon run cmd/main "用递归实现快速排序，对数组[5,3,8,1,9,2,7,4,6,0]排序"

# 查看目录并统计文件
moon run cmd/main "先调用工具查看当前目录有哪些文件，然后写一个程序打印文件数量"
```

## 📂 项目结构

```
mb-code-agent/
├── cmd/main/
│   ├── main.mbt          # CLI 入口：参数解析、REPL 交互模式
│   └── moon.pkg          # 可执行包配置
├── config.mbt             # 配置管理：从环境变量读取 API Key、Base URL、模型名
├── llm.mbt                # 大模型调用封装：Tool 结构、ToolCall 解析、HTTP 请求
├── agent.mbt              # 智能体核心：工具调用循环、代码生成、沙箱执行、代码分析
├── sandbox.mbt            # 沙箱执行：代码提取、临时项目创建、超时控制、输出截断
├── tools.mbt              # 内置工具定义：read_file、execute_command、get_current_time
├── ui.mbt                 # 终端 UI：ANSI 颜色、分隔线、代码块格式化
├── moon.mod               # 模块配置
├── moon.pkg               # 根包配置（库代码）
└── README.md
```

## 🧠 工作原理

1. **需求理解**：将用户需求 + 系统 Prompt 发送给大模型
2. **工具调用（可选）**：模型可主动调用工具探索环境（读文件、执行命令、查时间），工具结果回传后继续推理
3. **代码生成**：模型基于获取的信息生成 MoonBit 代码，用 ```moonbit 代码块包裹
4. **代码提取**：从模型回复中提取代码块内容
5. **沙箱执行**：代码写入临时 MoonBit 项目，调用 `moon run .` 执行（10秒超时）
6. **结果判断**：exit code 为 0 则成功，否则进入纠错流程
7. **自动纠错**：将报错信息作为用户消息加入对话历史，再次请求大模型修复代码（最多3轮）
8. **代码分析**：执行成功后，自动生成代码逻辑解释和优化建议

## 🛡️ 安全机制

- **执行超时**：默认 10 秒，防止无限循环卡死
- **输出截断**：超过 50 行自动截断，防止输出爆炸
- **临时目录清理**：每次执行前清理并重建临时目录
- **危险命令黑名单**：拦截 `rm -rf /`、`mkfs`、`dd if=`、fork bomb 等危险操作

## 🧰 技术栈

- **语言**：[MoonBit](https://www.moonbitlang.com/)
- **异步运行时**：`moonbitlang/async`（HTTP 客户端、子进程、文件系统）
- **大模型接口**：OpenAI 兼容 Chat Completions API（支持 Tool Use）
- **JSON 序列化**：MoonBit 内置 derive(ToJson, FromJson)
- **终端 UI**：ANSI 转义序列

## 📄 License

Apache-2.0
