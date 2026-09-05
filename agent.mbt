pub async fn run_agent(config : Config, user_request : String) -> Unit raise {
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
    println("\n========== 第 \{attempt} 轮 ==========")

    let raw_reply = chat(config, messages)
    let code = extract_code(raw_reply)

    println("--- 生成的代码 ---")
    println(code)

    let (exit_code, output) = execute_code(code)

    println("--- 执行结果 ---")
    println("exit code: \{exit_code}")
    println("output: \{output}")

    if exit_code == 0 {
      success = true
      println("\n========== 成功！第 \{attempt} 轮跑通 ==========")
      println("最终输出：\{output}")
    } else {
      let error_msg = "上面的代码执行失败了。exit code: \{exit_code}，报错信息：\n\{output}\n请根据报错修复代码，只输出完整的修复后代码，用```moonbit包裹，不要解释。"
      messages = messages + [RequestMessage::{ role: "user", content: error_msg }]
      println("--- 执行失败，将报错喂回模型进行下一轮修复 ---")
    }
  }

  if !success {
    println("\n========== 失败：已达到最大重试次数 \{max_retries} ==========")
  }
}
