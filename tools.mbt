fn read_file_tool() -> Tool {
  Tool::{
    name: "read_file",
    description: "Read a file from local disk and return its content",
    parameters: {
      "type": "object",
      "properties": {
        "path": { "type": "string", "description": "The absolute or relative path of the file to read" },
      },
      "required": ["path"],
    },
    execute: args => {
      guard @json.parse(args) is { "path": String(path), .. } else {
        "Error: Invalid arguments for read_file, expected {\"path\": string}"
      }
      @fs.read_file(path).text()
    },
  }
}

fn execute_command_tool() -> Tool {
  Tool::{
    name: "execute_command",
    description: "Execute a shell command and return its exit code and output. Dangerous commands are blocked.",
    parameters: {
      "type": "object",
      "properties": {
        "command": { "type": "string", "description": "The shell command to execute" },
      },
      "required": ["command"],
    },
    execute: args => {
      guard @json.parse(args) is { "command": String(cmd), .. } else {
        "Error: Invalid arguments for execute_command, expected {\"command\": string}"
      }
      let (exit_code, output) = execute_shell_command(cmd)
      "Exit code: \{exit_code}\nOutput:\n\{output}"
    },
  }
}

fn get_current_time_tool() -> Tool {
  Tool::{
    name: "get_current_time",
    description: "Get the current system date and time",
    parameters: {
      "type": "object",
      "properties": {},
    },
    execute: _ => {
      let (_, output) = @process.collect_output_merged("date", [])
      output.text()
    },
  }
}

fn get_builtin_tools() -> Array[Tool] {
  [read_file_tool(), execute_command_tool(), get_current_time_tool()]
}
