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

async fn execute_code(code : String) -> (Int, String) {
  let _ = @process.collect_output_merged("mkdir", ["-p", "/tmp/mb_agent_project"])
  @fs.write_file("/tmp/mb_agent_project/moon.mod", "name = \"tmp/agent-output\"\nversion = \"0.1.0\"\n")
  @fs.write_file("/tmp/mb_agent_project/moon.pkg", "options(\n  \"is-main\": true,\n)\n")
  @fs.write_file("/tmp/mb_agent_project/main.mbt", code)
  let (exit_code, output) = @process.collect_output_merged("sh", ["-c", "cd /tmp/mb_agent_project && moon run ."])
  (exit_code, output.text())
}
