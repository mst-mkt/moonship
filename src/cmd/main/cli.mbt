///|
pub enum Command {
  Prompt(PromptArgs)
  Version
  Help
  UnknownCommand(String)
}

///|
pub struct PromptArgs {
  status : Int
  cmd_duration : Int
  jobs : Int
  terminal_width : Int
}

///|
pub fn PromptArgs::default() -> PromptArgs {
  { status: 0, cmd_duration: 0, jobs: 0, terminal_width: 80 }
}

///|
pub fn parse_args(args : Array[String]) -> Command {
  if args.is_empty() {
    return Help
  }

  match args[0] {
    "prompt" => parse_prompt_args(args)
    "version" | "--version" | "-V" => Version
    "help" | "--help" | "-h" => Help
    _ => UnknownCommand(args[0])
  }
}

///|
fn parse_prompt_args(args : Array[String]) -> Command {
  let pa = args[1:]
    .iter()
    .fold(init=PromptArgs::default(), fn(pa, arg) {
      match extract_flag_value(arg) {
        Some(("status", v)) => { ..pa, status: parse_int_arg(v) }
        Some(("cmd-duration", v)) => { ..pa, cmd_duration: parse_int_arg(v) }
        Some(("jobs", v)) => { ..pa, jobs: parse_int_arg(v) }
        Some(("terminal-width", v)) =>
          { ..pa, terminal_width: parse_int_arg(v) }
        _ => pa
      }
    })
  Prompt(pa)
}

///|
/// Extract ("key", "value") from "--key=value"
fn extract_flag_value(arg : String) -> (String, String)? {
  guard arg.has_prefix("--") else { return None }
  arg[2:]
  .to_string()
  .split_once("=")
  .map(fn(pair) { (pair.0.to_string(), pair.1.to_string()) })
}

///|
fn parse_int_arg(s : String) -> Int {
  @strconv.parse_int(s) catch {
    _ => 0
  }
}
