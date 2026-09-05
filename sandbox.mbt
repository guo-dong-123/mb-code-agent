const TEMP_DIR = "/tmp/mb_agent_project"
const MAX_OUTPUT_LINES = 50
const EXECUTION_TIMEOUT_SECONDS = 10

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

fn truncate_output(output : String) -> String {
  let lines = output.split("\n").to_array()
  if lines.length() > MAX_OUTPUT_LINES {
    let mut result = ""
    let mut idx = 0
    while idx < MAX_OUTPUT_LINES {
      result = result + lines[idx].to_owned() + "\n"
      idx = idx + 1
    }
    result + "... (输出已截断，共 \{lines.length()} 行，仅显示前 \{MAX_OUTPUT_LINES} 行)"
  } else {
    output
  }
}

fn is_dangerous_command(cmd : String) -> Bool {
  let dangerous = ["rm -rf /", "rm -rf /*", "mkfs", "dd if=", ":(){ :|:& };:", "chmod -R 777 /", "shutdown", "reboot", "halt"]
  let mut idx = 0
  while idx < dangerous.length() {
    if cmd.contains(dangerous[idx]) {
      return true
    }
    idx = idx + 1
  }
  false
}

async fn execute_code(code : String) -> (Int, String) {
  // 清理并重建临时目录
  let _ = @process.collect_output_merged("rm", ["-rf", TEMP_DIR])
  let _ = @process.collect_output_merged("mkdir", ["-p", TEMP_DIR])

  @fs.write_file("\{TEMP_DIR}/moon.mod", "name = \"tmp/agent-output\"\nversion = \"0.1.0\"\n")
  @fs.write_file("\{TEMP_DIR}/moon.pkg", "options(\n  \"is-main\": true,\n)\n")
  @fs.write_file("\{TEMP_DIR}/main.mbt", code)

  // 用 perl alarm 实现超时控制（Mac/Linux 通用）
  let timeout_cmd = "cd \{TEMP_DIR} && perl -e 'alarm \{EXECUTION_TIMEOUT_SECONDS}; exec \"moon\", \"run\", \".\"'"
  let (exit_code, output) = @process.collect_output_merged("sh", ["-c", timeout_cmd])

  let output_text = output.text()
  let truncated = truncate_output(output_text)
  (exit_code, truncated)
}

pub async fn execute_shell_command(cmd : String) -> (Int, String) {
  if is_dangerous_command(cmd) {
    return (1, "Error: 检测到危险命令，已拒绝执行")
  }
  let (exit_code, output) = @process.collect_output_merged("sh", ["-c", cmd])
  (exit_code, truncate_output(output.text()))
}
