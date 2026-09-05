pub async fn run_agent(config : Config, user_request : String) -> Unit raise {
  print_header("mb-code-agent")
  print_info("用户需求：\{user_request}")

  let system_prompt = "你是MoonBit代码生成器。只输出代码，用```moonbit代码块包裹，不要任何解释。代码必须包含fn main函数，可直接通过moon run .运行。如果之前的代码报错了，根据报错信息修复，只输出完整的修复后代码。"

  let mut messages : Array[RequestMessage] = [
    RequestMessage::{ role: "system", content: system_prompt },
    RequestMessage::{ role: "user", content: user_request },
  ]

  let max_retries = 3
  let mut attempt = 0
  let mut success = false

  while attempt < max_retries && !success {
    attempt = attempt + 1
    print_section("第 \{attempt} 轮 / 共 \{max_retries} 轮")

    print_info("⏳ 大模型思考中...")
    let raw_reply = chat(config, messages)
    print_info("✅ 大模型回复完成")

    let code = extract_code(raw_reply)

    print_section("生成的代码")
    print_code(code)

    print_section("沙箱执行中...")
    let (exit_code, output) = execute_code(code)

    if exit_code == 0 {
      print_success("执行成功！exit code = \{exit_code}")
      print_section("运行结果")
      color_print(green, output)
      success = true
      print_success("🎉 第 \{attempt} 轮跑通！")
    } else {
      print_error("执行失败！exit code = \{exit_code}")
      print_section("报错信息")
      color_print(red, output)
      let error_msg = "上面的代码执行失败了。exit code: \{exit_code}，报错信息：\n\{output}\n请根据报错修复代码，只输出完整的修复后代码，用```moonbit包裹，不要解释。"
      messages = messages + [RequestMessage::{ role: "user", content: error_msg }]
      print_info("🔄 将报错喂回模型，进行下一轮修复...")
    }
  }

  if !success {
    print_error("已达到最大重试次数 \{max_retries}，未能成功执行")
  }
}
