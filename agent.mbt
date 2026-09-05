async fn explain_code(config : Config, code : String) -> Unit {
  print_section("代码解释与优化建议")
  print_info("🤖 正在生成代码分析...")

  let messages : Array[Json] = [
    { "role": "system", "content": "你是MoonBit代码评审专家。请用中文解释以下代码的核心逻辑，然后给出2-3条具体的优化建议（性能、可读性、规范等方面）。格式：先写【逻辑解释】，再写【优化建议】，每条建议一行。语言简洁专业。" },
    { "role": "user", "content": code },
  ]

  let message = chat(config, messages, [])
  if message is { "content": String(content), .. } {
    color_print(cyan, content)
  }
}

pub async fn run_agent(config : Config, user_request : String) -> Unit raise {
  print_header("mb-code-agent")
  print_info("用户需求：\{user_request}")

  let system_prompt = "你是一个MoonBit代码智能体。你可以调用工具来获取信息（读取文件、执行命令、查询时间），然后基于获取的信息生成MoonBit代码解决用户问题。最终必须输出可执行的MoonBit代码，用```moonbit代码块包裹，包含fn main函数。如果不需要调用工具，可以直接生成代码。"

  let tools = get_builtin_tools()
  let tool_map : Map[String, Tool] = {
    "read_file": read_file_tool(),
    "execute_command": execute_command_tool(),
    "get_current_time": get_current_time_tool(),
  }

  let mut messages : Array[Json] = [
    { "role": "system", "content": system_prompt },
    { "role": "user", "content": user_request },
  ]

  let max_turns = 10
  let mut turn = 0
  let mut final_reply = ""
  let mut final_code = ""

  while turn < max_turns {
    turn = turn + 1
    print_section("对话轮次 \{turn}")

    print_info("⏳ 大模型思考中...")
    let message = chat(config, messages, tools)
    print_info("✅ 大模型回复完成")
    messages = messages + [message]

    if message is { "content": String(content), .. } {
      if content.length() > 0 {
        print_section("模型回复")
        println(content)
        final_reply = content
      }
    }

    let tool_calls : Array[ToolCall] = if message is { "tool_calls": tool_calls_json, .. } {
      @json.from_json(tool_calls_json)
    } else {
      []
    }

    if tool_calls.is_empty() {
      let code = extract_code(final_reply)
      if code.length() > 0 && code != final_reply {
        final_code = code
        print_section("生成的代码")
        print_code(code)
        print_section("沙箱执行中...")
        let (exit_code, output) = execute_code(code)
        if exit_code == 0 {
          print_success("执行成功！exit code = \{exit_code}")
          print_section("运行结果")
          color_print(green, output)
          explain_code(config, code)
        } else {
          print_error("执行失败！exit code = \{exit_code}")
          print_section("报错信息")
          color_print(red, output)
        }
      } else {
        print_info("模型未生成代码，以上为最终回复")
      }
      break
    }

    print_section("工具调用（\{tool_calls.length()} 个）")
    for tool_call in tool_calls {
      print_info("🔧 调用工具：\{tool_call.function.name}")
      print_info("   参数：\{tool_call.function.arguments}")

      let tool_result = match tool_map.get(tool_call.function.name) {
        Some(tool) => (tool.execute)(tool_call.function.arguments)
        None => "Error: Tool not found: \{tool_call.function.name}"
      }

      print_section("工具返回结果")
      color_print(cyan, tool_result)

      let tool_message = {
        "role": "tool",
        "content": tool_result,
        "tool_call_id": tool_call.id,
      }
      messages = messages + [tool_message]
    }
  }

  if turn >= max_turns {
    print_error("已达到最大对话轮次 \{max_turns}")
  }
}

pub async fn run_agent_demo() -> Unit raise {
  print_header("mb-code-agent")
  print_info("用户需求：写一个计算斐波那契数列第10项的程序")
  print_info("🎯 演示模式：使用预设模拟回复，沙箱执行为真实")

  // 轮次1：模拟工具调用
  print_section("对话轮次 1")
  print_section("模型回复")
  println("我先查看当前目录结构，确认环境后再编写代码。")

  print_section("工具调用（1 个）")
  print_info("🔧 调用工具：execute_command")
  print_info("   参数：{\"command\": \"ls -la\"}")

  print_section("工具返回结果")
  let (_, ls_output) = @process.collect_output_merged("sh", ["-c", "ls -la | head -20"])
  color_print(cyan, ls_output.text())

  // 轮次2：模拟代码生成
  print_section("对话轮次 2")
  print_section("模型回复")
  let demo_code = "fn fib(n: Int) -> Int {\n  if n <= 1 {\n    n\n  } else {\n    fib(n - 1) + fib(n - 2)\n  }\n}\n\nfn main {\n  let result = fib(10)\n  println(\"fib(10) = \\{result}\")\n}"
  println("已确认环境为 MoonBit 项目，以下是生成的代码：\n")
  println("```moonbit")
  println(demo_code)
  println("```")

  // 真实沙箱执行
  print_section("生成的代码")
  print_code(demo_code)
  print_section("沙箱执行中...")
  let (exit_code, output) = execute_code(demo_code)

  if exit_code == 0 {
    print_success("执行成功！exit code = \{exit_code}")
    print_section("运行结果")
    color_print(green, output)

    // 预设代码分析
    print_section("代码解释与优化建议")
    color_print(cyan, "【逻辑解释】")
    color_print(cyan, "该代码使用递归实现斐波那契数列计算。fib 函数在 n <= 1 时返回 n，否则返回 fib(n-1) + fib(n-2)。main 函数计算 fib(10) 并打印结果。")
    color_print(cyan, "")
    color_print(cyan, "【优化建议】")
    color_print(cyan, "1. 当前递归实现存在大量重复计算，时间复杂度 O(2^n)，建议改用迭代或记忆化搜索将复杂度降至 O(n)。")
    color_print(cyan, "2. 可增加输入校验，处理负数输入的边界情况。")
    color_print(cyan, "3. 斐波那契数列增长较快，较大 n 值可能导致 Int 溢出，建议根据需求考虑溢出检查。")
  } else {
    print_error("执行失败！exit code = \{exit_code}")
    print_section("报错信息")
    color_print(red, output)
  }
}
