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

async fn chat(config : Config, messages : Array[RequestMessage]) -> String raise {
  let request = ChatRequest::{
    model: config.model,
    messages: messages,
  }
  let (_, body) = @http.post(
    "\{config.base_url}/chat/completions",
    ToJson::to_json(request),
    headers={
      "Authorization": "Bearer \{config.api_key}",
      "Content-Type": "application/json",
    },
  )
  let result : ChatResponse = body.json() |> @json.from_json()
  result.choices[0].message.content
}
