///|
enum Command {
  Prompt(PromptArgs)
  Timings(PromptArgs)
  Explain(PromptArgs)
  Module(String, PromptArgs)
  ModuleList
  Init(String, Bool)
  CacheClear
  Time
  PrintConfig(Bool)
  BugReport
  Completions(String)
  Session
  Schema
  Version
  Help
  UnknownCommand(String)
  UnknownShell
}

///|
struct PromptArgs {
  status : Int
  pipestatus : Array[String]
  cmd_duration : Int
  jobs : Int
  terminal_width : Int
  keymap : String
  path : String
  logical_path : String
  shlvl : Int
  is_async : Bool
}

///|
fn parse_args(args : Array[String]) -> Command {
  guard not(args.is_empty()) else { return Help }

  match args[0] {
    "prompt" => parse_prompt_args(args[1:].to_array(), fn(pa) { Prompt(pa) })
    "timings" => parse_prompt_args(args[1:].to_array(), fn(pa) { Timings(pa) })
    "explain" => parse_prompt_args(args[1:].to_array(), fn(pa) { Explain(pa) })
    "module" => parse_module_command(args)
    "init" => parse_init_command(args)
    "cache" =>
      if args.length() > 1 && args[1] == "clear" {
        CacheClear
      } else {
        Help
      }
    "bug-report" => BugReport
    "completions" =>
      if args.length() > 1 {
        Completions(args[1])
      } else {
        Help
      }
    "session" => Session
    "time" => Time
    "print-config" => {
      let is_default = args[1:]
        .to_array()
        .iter()
        .any(fn(a) { a == "--default" || a == "-d" })
      PrintConfig(is_default)
    }
    "schema" => Schema
    "version" | "--version" | "-V" => Version
    "help" | "--help" | "-h" => Help
    _ => UnknownCommand(args[0])
  }
}

///|
fn parse_prompt_args(
  argv : Array[String],
  ctor : (PromptArgs) -> Command,
) -> Command {
  let status = Ref::new("0")
  let pipestatus_raw = Ref::new("")
  let cmd_duration = Ref::new("0")
  let jobs = Ref::new("0")
  let terminal_width = Ref::new("80")
  let keymap = Ref::new("")
  let path = Ref::new("")
  let logical_path = Ref::new("")
  let shlvl = Ref::new("0")
  let is_async = Ref::new(false)

  let spec : Array[(String, String, @ArgParser.Spec, String)] = [
    ("--status", "-s", Set_string(status), "exit code of last command"),
    (
      "--pipestatus",
      "",
      Set_string(pipestatus_raw),
      "pipe status of last command",
    ),
    (
      "--cmd-duration",
      "-d",
      Set_string(cmd_duration),
      "duration of last command",
    ),
    ("--jobs", "-j", Set_string(jobs), "number of background jobs"),
    (
      "--terminal-width",
      "-w",
      Set_string(terminal_width),
      "terminal width in columns",
    ),
    ("--keymap", "-k", Set_string(keymap), "vim keymap mode"),
    ("--path", "-p", Set_string(path), "override current directory"),
    (
      "--logical-path",
      "-P",
      Set_string(logical_path),
      "logical path for display",
    ),
    ("--shlvl", "", Set_string(shlvl), "shell nesting level"),
    ("--async", "", Set(is_async), "recompute and update cache"),
  ]

  @ArgParser.parse(spec, fn(_rest) {  }, "", argv) catch {
    _ => ()
  }

  let pipestatus = if pipestatus_raw.val.is_empty() {
    []
  } else {
    pipestatus_raw.val.split(" ").map(fn(s) { s.to_string() }).collect()
  }

  ctor({
    status: parse_int_arg(status.val),
    pipestatus,
    cmd_duration: parse_int_arg(cmd_duration.val),
    jobs: parse_int_arg(jobs.val),
    terminal_width: parse_int_arg(terminal_width.val),
    keymap: keymap.val,
    path: path.val,
    logical_path: logical_path.val,
    shlvl: parse_int_arg(shlvl.val),
    is_async: is_async.val,
  })
}

///|
fn parse_module_command(args : Array[String]) -> Command {
  guard args.length() > 1 else { return Help }

  if args[1] == "--list" || args[1] == "-l" {
    return ModuleList
  }

  let name = args[1]
  let rest = args[2:].to_array()
  parse_prompt_args(rest, fn(pa) { Module(name, pa) })
}

///|
fn parse_init_command(args : Array[String]) -> Command {
  guard args.length() > 1 else { return UnknownShell }

  let shell = args[1]
  let print_full = args[2:]
    .to_array()
    .iter()
    .any(fn(a) { a == "--print-full-init" })

  Init(shell, print_full)
}

///|
fn parse_int_arg(s : String) -> Int {
  @strconv.parse_int(s) catch {
    _ => 0
  }
}
