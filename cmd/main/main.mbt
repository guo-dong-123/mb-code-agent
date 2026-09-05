async fn main raise {
  let args = @env.args()
  if args.length() < 2 {
    println("Usage: mb-code-agent \"your request\"")
    println("")
    println("Environment variables:")
    println("  MB_AGENT_API_KEY   - API key (required)")
    println("  MB_AGENT_BASE_URL  - API base URL (default: DashScope compatible mode)")
    println("  MB_AGENT_MODEL     - Model name (default: qwen3.8-max)")
    println("")
    println("Example:")
    println("  export MB_AGENT_API_KEY=\"sk-xxx\"")
    println("  moon run cmd/main \"写一个计算斐波那契数列第10项的程序\"")
    panic()
  }

  let user_request = args[1]
  let config = @agent.Config::from_env()

  println("用户需求：\{user_request}")
  @agent.run_agent(config, user_request)
}
