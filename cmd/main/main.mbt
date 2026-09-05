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
  let user_request = "写一个计算斐波那契数列第10项的程序，直接打印结果"

  let system_prompt = "你是MoonBit代码生成器。只输出代码，用```moonbit代码块包裹，不要任何解释。代码必须包含fn main函数，可直接通过moon run运行。"

  let request = ChatRequest::{
    model: "qwen3.8-max",
    messages: [
      RequestMessage::{ role: "system", content: system_prompt },
      RequestMessage::{ role: "user", content: user_request },
    ],
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
  let content = result.choices[0].message.content

  println("=== 模型回复 ===")
  println(content)

  let code = extract_code(content)
  println("=== 提取的代码 ===")
  println(code)

  let _ = @process.collect_output_merged("mkdir", ["-p", "/tmp/mb_agent_project"])

  @fs.write_file("/tmp/mb_agent_project/moon.mod", "name = \"tmp/agent-output\"\nversion = \"0.1.0\"\n")
  @fs.write_file("/tmp/mb_agent_project/moon.pkg", "options(\n  \"is-main\": true,\n)\n")
  @fs.write_file("/tmp/mb_agent_project/main.mbt", code)

  let (exit_code, output) = @process.collect_output_merged("sh", ["-c", "cd /tmp/mb_agent_project && moon run ."])

  println("=== 执行结果 ===")
  println("exit code: \{exit_code}")
  println("output: \{output.text()}")
}
