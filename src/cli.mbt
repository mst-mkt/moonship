///|
enum Command {
  Prompt(PromptArgs)
  Timings(PromptArgs)
  Module(String, PromptArgs)
  ModuleList
  Init(String)
  CacheClear
  Time
  PrintConfig
  Version
  Help
  UnknownCommand(String)
  UnknownShell
}

///|
struct PromptArgs {
  status : Int
  cmd_duration : Int
  jobs : Int
  terminal_width : Int
  is_async : Bool
}

///|
fn PromptArgs::default() -> PromptArgs {
  { status: 0, cmd_duration: 0, jobs: 0, terminal_width: 80, is_async: false }
}

///|
fn parse_args(args : Array[String]) -> Command {
  guard not(args.is_empty()) else { return Help }

  match args[0] {
    "prompt" => parse_prompt_args(args, fn(pa) { Prompt(pa) })
    "timings" => parse_prompt_args(args, fn(pa) { Timings(pa) })
    "module" => parse_module_command(args)
    "init" => if args.length() > 1 { Init(args[1]) } else { UnknownShell }
    "cache" =>
      if args.length() > 1 && args[1] == "clear" {
        CacheClear
      } else {
        Help
      }
    "time" => Time
    "print-config" => PrintConfig
    "version" | "--version" | "-V" => Version
    "help" | "--help" | "-h" => Help
    _ => UnknownCommand(args[0])
  }
}

///|
fn parse_prompt_args(
  args : Array[String],
  ctor : (PromptArgs) -> Command,
) -> Command {
  let pa = args[1:]
    .iter()
    .fold(init=PromptArgs::default(), fn(pa, arg) {
      if arg == "--async" {
        return { ..pa, is_async: true }
      }

      match extract_flag_value(arg) {
        Some(("status", v)) => { ..pa, status: parse_int_arg(v) }
        Some(("cmd-duration", v)) => { ..pa, cmd_duration: parse_int_arg(v) }
        Some(("jobs", v)) => { ..pa, jobs: parse_int_arg(v) }
        Some(("terminal-width", v)) =>
          { ..pa, terminal_width: parse_int_arg(v) }
        _ => pa
      }
    })
  ctor(pa)
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
fn parse_module_command(args : Array[String]) -> Command {
  guard args.length() > 1 else { return Help }

  if args[1] == "--list" || args[1] == "-l" {
    return ModuleList
  }

  let name = args[1]
  let rest = Array::new()
  rest.push("module")
  for i = 2; i < args.length(); i = i + 1 {
    rest.push(args[i])
  }
  parse_prompt_args(rest, fn(pa) { Module(name, pa) })
}

///|
fn parse_int_arg(s : String) -> Int {
  @strconv.parse_int(s) catch {
    _ => 0
  }
}
