pub struct Config {
  api_key : String
  base_url : String
  model : String
}

pub fn Config::from_env() -> Config {
  let api_key = match @env.get_env_var("MB_AGENT_API_KEY") {
    Some(v) => v
    None => {
      println("Error: MB_AGENT_API_KEY environment variable not set")
      panic()
    }
  }
  let base_url = match @env.get_env_var("MB_AGENT_BASE_URL") {
    Some(v) => v
    None => "https://dashscope.aliyuncs.com/compatible-mode/v1"
  }
  let model = match @env.get_env_var("MB_AGENT_MODEL") {
    Some(v) => v
    None => "qwen3.8-max"
  }
  Config::{ api_key, base_url, model }
}
