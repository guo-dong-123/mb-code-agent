# mb-code-agent

基于 MoonBit 实现的终端代码智能体。输入自然语言需求，自动生成 MoonBit 代码并在本地沙箱中执行，支持多轮自动纠错。

## 功能特性

- **自然语言生成代码**：描述需求，大模型自动生成 MoonBit 代码
- **本地沙箱执行**：生成的代码写入临时项目，调用 `moon run` 执行，捕获输出和报错
- **多轮自动纠错**：执行失败时，自动将报错信息喂回大模型进行修复，最多重试 3 轮
- **OpenAI 兼容接口**：支持任意 OpenAI 兼容的大模型 API（默认通义千问 DashScope）
- **环境变量配置**：API Key、Base URL、模型名通过环境变量配置，不硬编码

## 安装

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

## 配置

设置环境变量：

```bash
# 必填：API Key
export MB_AGENT_API_KEY="sk-your-api-key"

# 可选：API Base URL（默认通义千问 DashScope 兼容模式）
export MB_AGENT_BASE_URL="https://dashscope.aliyuncs.com/compatible-mode/v1"

# 可选：模型名称（默认 qwen3.8-max）
export MB_AGENT_MODEL="qwen3.8-max"
```

支持其他 OpenAI 兼容接口，例如：

```bash
# OpenAI
export MB_AGENT_BASE_URL="https://api.openai.com/v1"
export MB_AGENT_MODEL="gpt-4o-mini"

# DeepSeek
export MB_AGENT_BASE_URL="https://api.deepseek.com/v1"
export MB_AGENT_MODEL="deepseek-chat"
```

## 使用方法

```bash
moon run cmd/main "你的需求描述"
```

### 示例

```bash
# 计算斐波那契数列
moon run cmd/main "写一个计算斐波那契数列第10项的程序"

# 快速排序
moon run cmd/main "用递归实现快速排序，对数组[5,3,8,1,9,2,7,4,6,0]排序"

# 素数计算
moon run cmd/main "计算1到100的所有素数并打印"
```

### 运行输出示例

```
用户需求：写一个计算1到10求和的程序

========== 第 1 轮 ==========
--- 生成的代码 ---
fn sum_to(n: Int) -> Int {
  if n == 0 {
    0
  } else {
    n + sum_to(n - 1)
  }
}

fn main {
  let result = sum_to(10)
  println(result.to_string())
}
--- 执行结果 ---
exit code: 0
output: 55

========== 成功！第 1 轮跑通 ==========
最终输出：55
```

## 项目结构

```
mb-code-agent/
├── cmd/main/
│   ├── main.mbt          # CLI 入口：参数解析、环境变量读取、调用智能体
│   └── moon.pkg          # 可执行包配置
├── config.mbt             # 配置管理：从环境变量读取 API Key、Base URL、模型名
├── llm.mbt                # 大模型调用封装：HTTP 请求、消息结构、响应解析
├── agent.mbt              # 智能体核心：Prompt 构造、多轮纠错循环
├── sandbox.mbt            # 沙箱执行：代码提取、临时项目创建、moon run 调用
├── moon.mod               # 模块配置
├── moon.pkg               # 根包配置（库代码）
└── README.md
```

## 技术栈

- **语言**：[MoonBit](https://www.moonbitlang.com/)
- **异步运行时**：`moonbitlang/async`（HTTP 客户端、子进程、文件系统）
- **大模型接口**：OpenAI 兼容 Chat Completions API
- **JSON 序列化**：MoonBit 内置 derive(ToJson, FromJson)

## 工作原理

1. **代码生成**：将用户需求 + 系统 Prompt 发送给大模型，要求输出 MoonBit 代码
2. **代码提取**：从模型回复中提取 ```moonbit 代码块内容
3. **沙箱执行**：将代码写入临时 MoonBit 项目，调用 `moon run .` 执行
4. **结果判断**：exit code 为 0 则成功，否则进入纠错流程
5. **自动纠错**：将报错信息作为用户消息加入对话历史，再次请求大模型修复代码
6. **循环终止**：成功或达到最大重试次数（3 轮）后结束

## License

Apache-2.0
