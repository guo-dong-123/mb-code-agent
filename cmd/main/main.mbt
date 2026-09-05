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

async fn main raise {
  let request = ChatRequest::{
    model: "qwen3.8-max",
    messages: [
      RequestMessage::{
        role: "user",
        content: "你好，请用一句话介绍你自己",
      },
    ],
  }

  let (response, body) = @http.post(
    "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions",
    ToJson::to_json(request),
    headers={
      "Authorization": "Bearer sk-44989218a6344be1bfdd4b99d25c9377",
      "Content-Type": "application/json",
    },
  )

  println("status: \{response.code}")

  let result : ChatResponse = body.json() |> @json.from_json()
  println("model reply: \{result.choices[0].message.content}")
}
