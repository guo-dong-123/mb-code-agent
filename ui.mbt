// ANSI 颜色和终端 UI 工具

let red = "\u001b[31m"
let green = "\u001b[32m"
let yellow = "\u001b[33m"
let blue = "\u001b[34m"
let magenta = "\u001b[35m"
let cyan = "\u001b[36m"
let bold = "\u001b[1m"
let reset = "\u001b[0m"

fn color_print(color : String, text : String) -> Unit {
  println("\{color}\{text}\{reset}")
}

fn print_header(title : String) -> Unit {
  let line = "============================================================"
  color_print(cyan + bold, line)
  color_print(cyan + bold, "  \{title}")
  color_print(cyan + bold, line)
}

fn print_section(title : String) -> Unit {
  color_print(yellow + bold, "\n--- \{title} ---")
}

fn print_success(msg : String) -> Unit {
  color_print(green + bold, "\n✅ \{msg}")
}

fn print_error(msg : String) -> Unit {
  color_print(red + bold, "\n❌ \{msg}")
}

fn print_info(msg : String) -> Unit {
  color_print(blue, "ℹ️  \{msg}")
}

fn print_code(code : String) -> Unit {
  color_print(magenta, "```moonbit")
  println(code)
  color_print(magenta, "```")
}

fn print_spinner_frame(frame : Int) -> String {
  let frames = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
  frames[frame % frames.length()]
}
