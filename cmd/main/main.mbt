struct RequestMessage {
  role : String
  content : String
} derive(ToJson)

struct ChatRequest {
  model : String
  messages : Array[RequestMessage]
} derive(ToJson)

struct ResponseMessage {
  role : String
  content : String
} derive(ToJson, @json.FromJson)

struct Choice {
  message : ResponseMessage
} derive(ToJson, @json.FromJson)

struct ChatResponse {
  choices : Array[Choice]
} derive(ToJson, @json.FromJson)

fn extract_code(content : String) -> String {
  let parts = content.split("```").to_array()
  if parts.length() >= 3 {
    let code = parts[1].to_owned()
    let lines = code.split("\n").to_array()
    if lines.length() > 0 && lines[0].to_owned().contains("moonbit") {
      let mut result = ""
      let mut idx = 1
      while idx < lines.length() {
        result = result + lines[idx].to_owned() + "\n"
        idx = idx + 1
      }
      result
    } else {
      code
    }
  } else {
    content
  }
}

async fn main raise {
  let user_request = "写一个程序，用递归实现快速排序，对数组[5,3,8,1,9,2,7,4,6,0]排序，打印排序后的结果"

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

    // 1. 调用大模型生成代码
    let request = ChatRequest::{
      model: "qwen3.8-max",
      messages: messages,
    }
    let (_, body) = @http.post(
      "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions",
      ToJson::to_json(request),
      headers={
        "Authorization": "Bearer sk-44989218a6344be1bfdd4b99d25c9377",
        "Content-Type": "application/json",
      },
    )
    let result : ChatResponse = body.json() |> @json.from_json()
    let raw_reply = result.choices[0].message.content
    let code = extract_code(raw_reply)

    println("--- 生成的代码 ---")
    println(code)

    // 2. 写入临时项目并执行
    let _ = @process.collect_output_merged("mkdir", ["-p", "/tmp/mb_agent_project"])
    @fs.write_file("/tmp/mb_agent_project/moon.mod", "name = \"tmp/agent-output\"\nversion = \"0.1.0\"\n")
    @fs.write_file("/tmp/mb_agent_project/moon.pkg", "options(\n  \"is-main\": true,\n)\n")
    @fs.write_file("/tmp/mb_agent_project/main.mbt", code)

    let (exit_code, output) = @process.collect_output_merged("sh", ["-c", "cd /tmp/mb_agent_project && moon run ."])

    println("--- 执行结果 ---")
    println("exit code: \{exit_code}")
    println("output: \{output.text()}")

    // 3. 判断成功或失败
    if exit_code == 0 {
      success = true
      println("\n========== 成功！第 \{attempt} 轮跑通 ==========")
      println("最终输出：\{output.text()}")
    } else {
      // 失败，把报错喂回模型
      let error_msg = "上面的代码执行失败了。exit code: \{exit_code}，报错信息：\n\{output.text()}\n请根据报错修复代码，只输出完整的修复后代码，用```moonbit包裹，不要解释。"
      messages = messages + [RequestMessage::{ role: "user", content: error_msg }]
      println("--- 执行失败，将报错喂回模型进行下一轮修复 ---")
    }
  }

  if !success {
    println("\n========== 失败：已达到最大重试次数 \{max_retries} ==========")
  }
}
