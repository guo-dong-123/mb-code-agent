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

  while turn < max_turns {
    turn = turn + 1
    print_section("对话轮次 \{turn}")

    print_info("⏳ 大模型思考中...")
    let message = chat(config, messages, tools)
    print_info("✅ 大模型回复完成")
    messages = messages + [message]

    // 打印模型的文本回复（如果有）
    if message is { "content": String(content), .. } {
      if content.length() > 0 {
        print_section("模型回复")
        println(content)
        final_reply = content
      }
    }

    // 检查是否有工具调用
    let tool_calls : Array[ToolCall] = if message is { "tool_calls": tool_calls_json, .. } {
      @json.from_json(tool_calls_json)
    } else {
      []
    }

    if tool_calls.is_empty() {
      // 没有工具调用，尝试提取代码并执行
      let code = extract_code(final_reply)
      if code.length() > 0 && code != final_reply {
        print_section("生成的代码")
        print_code(code)
        print_section("沙箱执行中...")
        let (exit_code, output) = execute_code(code)
        if exit_code == 0 {
          print_success("执行成功！exit code = \{exit_code}")
          print_section("运行结果")
          color_print(green, output)
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

    // 执行工具调用
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
