struct Function {
  name : String
  arguments : String
} derive(ToJson, @json.FromJson)

struct ToolCall {
  id : String
  function : Function
} derive(ToJson, @json.FromJson)

struct Tool {
  name : String
  description : String
  parameters : Json
  execute : async (String) -> String
}

impl ToJson for Tool with to_json(self : Tool) -> Json {
  {
    "type": "function",
    "function": {
      "name": self.name,
      "description": self.description,
      "parameters": self.parameters,
    },
  }
}

struct ChatRequest {
  model : String
  messages : Array[Json]
  tools : Array[Tool]
} derive(ToJson)

struct Choice {
  message : Json
} derive(ToJson, @json.FromJson)

struct ChatResponse {
  choices : Array[Choice]
} derive(ToJson, @json.FromJson)

async fn chat(config : Config, messages : Array[Json], tools : Array[Tool]) -> Json raise {
  let request = ChatRequest::{
    model: config.model,
    messages: messages,
    tools: tools,
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
  result.choices[0].message
}
