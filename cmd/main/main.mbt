async fn read_line() -> String raise {
  let (_, output) = @process.collect_output_merged("perl", ["-e", "chomp($line = <STDIN>); print $line"])
  output.text()
}

async fn repl(config : @agent.Config) -> Unit raise {
  println("")
  println("\u{001b}[36m\u{001b}[1m╔══════════════════════════════════════════╗\u{001b}[0m")
  println("\u{001b}[36m\u{001b}[1m║   mb-code-agent 交互式模式   ║\u{001b}[0m")
  println("\u{001b}[36m\u{001b}[1m╚══════════════════════════════════════════╝\u{001b}[0m")
  println("")
  println("输入你的需求，自动生成 MoonBit 代码并执行")
  println("命令：\u{001b}[33m/help\u{001b}[0m 查看帮助，\u{001b}[33m/exit\u{001b}[0m 退出")
  println("")

  let mut running = true
  while running {
    println("\u{001b}[32m\u{001b}[1mmb-agent>\u{001b}[0m")
    let input = read_line()
    if input == "/exit" || input == "quit" || input == "q" {
      running = false
      println("")
      println("\u{001b}[36m再见！感谢使用 mb-code-agent\u{001b}[0m")
    } else if input == "/help" || input == "h" {
      println("")
      println("\u{001b}[33m可用命令：\u{001b}[0m")
      println("  /exit   退出程序")
      println("  /clear  清屏")
      println("  /help   显示此帮助")
      println("")
      println("\u{001b}[33m使用说明：\u{001b}[0m")
      println("  直接输入需求描述，智能体将自动：")
      println("  1. 调用工具探索环境（读文件、执行命令、查时间）")
      println("  2. 生成 MoonBit 代码")
      println("  3. 在沙箱中执行并返回结果")
      println("  4. 自动解释代码并给出优化建议")
      println("")
    } else if input == "/clear" || input == "c" {
      let _ = @process.collect_output_merged("clear", [])
    } else if input.length() > 0 {
      println("")
      @agent.run_agent(config, input)
      println("")
      println("\u{001b}[36m─────────────────────────────────────────────\u{001b}[0m")
      println("")
    }
  }
}

async fn main raise {
  let args = @env.args()

  // 演示模式：无需 API Key
  if args.length() >= 2 && args[1] == "--demo" {
    @agent.run_agent_demo()
    return
  }

  let config = @agent.Config::from_env()

  if args.length() < 2 {
    repl(config)
  } else {
    let user_request = args[1]
    @agent.run_agent(config, user_request)
  }
}
