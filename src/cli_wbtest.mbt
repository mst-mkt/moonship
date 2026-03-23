///|
test "prompt: with options" {
  let cmd = parse_args(["prompt", "--status", "1", "--cmd-duration", "500"])
  match cmd {
    Prompt(pa) => {
      assert_eq(pa.status, 1)
      assert_eq(pa.cmd_duration, 500)
      assert_eq(pa.jobs, 0)
      assert_eq(pa.terminal_width, 80)
    }
    _ => fail("Expected Prompt")
  }
}

///|
test "prompt: short flags" {
  let cmd = parse_args([
    "prompt", "-s", "42", "-d", "100", "-j", "2", "-w", "120",
  ])
  match cmd {
    Prompt(pa) => {
      assert_eq(pa.status, 42)
      assert_eq(pa.cmd_duration, 100)
      assert_eq(pa.jobs, 2)
      assert_eq(pa.terminal_width, 120)
    }
    _ => fail("Expected Prompt")
  }
}

///|
test "prompt: defaults" {
  let cmd = parse_args(["prompt"])
  match cmd {
    Prompt(pa) => {
      assert_eq(pa.status, 0)
      assert_eq(pa.cmd_duration, 0)
    }
    _ => fail("Expected Prompt")
  }
}

///|
test "prompt: all options" {
  let cmd = parse_args([
    "prompt", "--status", "127", "--cmd-duration", "1000", "--jobs", "3", "--terminal-width",
    "120",
  ])
  match cmd {
    Prompt(pa) => {
      assert_eq(pa.status, 127)
      assert_eq(pa.cmd_duration, 1000)
      assert_eq(pa.jobs, 3)
      assert_eq(pa.terminal_width, 120)
    }
    _ => fail("Expected Prompt")
  }
}

///|
test "prompt: --async flag" {
  let cmd = parse_args(["prompt", "--async", "--status", "1"])
  match cmd {
    Prompt(pa) => {
      assert_true(pa.is_async)
      assert_eq(pa.status, 1)
    }
    _ => fail("Expected Prompt")
  }
}

///|
test "prompt: default is_async is false" {
  let cmd = parse_args(["prompt", "--status", "0"])
  match cmd {
    Prompt(pa) => assert_true(not(pa.is_async))
    _ => fail("Expected Prompt")
  }
}

///|
test "prompt: --path" {
  let cmd = parse_args(["prompt", "--path", "/home/user/project"])
  match cmd {
    Prompt(pa) => assert_eq(pa.path, "/home/user/project")
    _ => fail("Expected Prompt")
  }
}

///|
test "prompt: -p short flag" {
  let cmd = parse_args(["prompt", "-p", "/tmp"])
  match cmd {
    Prompt(pa) => assert_eq(pa.path, "/tmp")
    _ => fail("Expected Prompt")
  }
}

///|
test "prompt: --keymap" {
  let cmd = parse_args(["prompt", "--keymap", "vicmd"])
  match cmd {
    Prompt(pa) => assert_eq(pa.keymap, "vicmd")
    _ => fail("Expected Prompt")
  }
}

///|
test "prompt: -k short flag" {
  let cmd = parse_args(["prompt", "-k", "visual"])
  match cmd {
    Prompt(pa) => assert_eq(pa.keymap, "visual")
    _ => fail("Expected Prompt")
  }
}

///|
test "version / help" {
  assert_true(parse_args(["version"]) is Version)
  assert_true(parse_args(["--version"]) is Version)
  assert_true(parse_args(["-V"]) is Version)
  assert_true(parse_args(["help"]) is Help)
  assert_true(parse_args(["--help"]) is Help)
  assert_true(parse_args(["-h"]) is Help)
}

///|
test "print-config" {
  match parse_args(["print-config"]) {
    PrintConfig(is_default) => assert_false(is_default)
    _ => fail("Expected PrintConfig")
  }
}

///|
test "print-config: --default" {
  match parse_args(["print-config", "--default"]) {
    PrintConfig(is_default) => assert_true(is_default)
    _ => fail("Expected PrintConfig")
  }
}

///|
test "print-config: -d" {
  match parse_args(["print-config", "-d"]) {
    PrintConfig(is_default) => assert_true(is_default)
    _ => fail("Expected PrintConfig")
  }
}

///|
test "init: with shell" {
  match parse_args(["init", "zsh"]) {
    Init(shell, print_full) => {
      assert_eq(shell, "zsh")
      assert_false(print_full)
    }
    _ => fail("Expected Init")
  }
}

///|
test "init: --print-full-init" {
  match parse_args(["init", "bash", "--print-full-init"]) {
    Init(shell, print_full) => {
      assert_eq(shell, "bash")
      assert_true(print_full)
    }
    _ => fail("Expected Init")
  }
}

///|
test "init: no shell" {
  assert_true(parse_args(["init"]) is UnknownShell)
}

///|
test "cache clear" {
  assert_true(parse_args(["cache", "clear"]) is CacheClear)
}

///|
test "cache: no subcommand shows help" {
  assert_true(parse_args(["cache"]) is Help)
}

///|
test "time" {
  assert_true(parse_args(["time"]) is Time)
}

///|
test "timings: default" {
  match parse_args(["timings"]) {
    Timings(pa) => assert_eq(pa.status, 0)
    _ => fail("Expected Timings")
  }
}

///|
test "timings: with options" {
  match parse_args(["timings", "--status", "1"]) {
    Timings(pa) => assert_eq(pa.status, 1)
    _ => fail("Expected Timings")
  }
}

///|
test "no args is Help" {
  assert_true(parse_args([]) is Help)
}

///|
test "unknown command" {
  match parse_args(["foo"]) {
    UnknownCommand(name) => assert_eq(name, "foo")
    _ => fail("Expected UnknownCommand")
  }
}

///|
test "parse int" {
  assert_eq(parse_int_arg("42"), 42)
  assert_eq(parse_int_arg("-1"), -1)
  assert_eq(parse_int_arg("abc"), 0)
  assert_eq(parse_int_arg(""), 0)
}

///|
test "module: with --path" {
  let cmd = parse_args(["module", "golang", "--path", "/home/user/project"])
  match cmd {
    Module(name, pa) => {
      assert_eq(name, "golang")
      assert_eq(pa.path, "/home/user/project")
    }
    _ => fail("Expected Module")
  }
}

///|
test "module: --list" {
  assert_true(parse_args(["module", "--list"]) is ModuleList)
  assert_true(parse_args(["module", "-l"]) is ModuleList)
}

///|
test "config: no args" {
  match parse_args(["config"]) {
    Config(name, value) => {
      assert_eq(name, "")
      assert_eq(value, "")
    }
    _ => fail("Expected Config")
  }
}

///|
test "config: with name" {
  match parse_args(["config", "format"]) {
    Config(name, value) => {
      assert_eq(name, "format")
      assert_eq(value, "")
    }
    _ => fail("Expected Config")
  }
}

///|
test "config: with name and value" {
  match parse_args(["config", "format", "$all"]) {
    Config(name, value) => {
      assert_eq(name, "format")
      assert_eq(value, "$all")
    }
    _ => fail("Expected Config")
  }
}

///|
test "bug-report" {
  assert_true(parse_args(["bug-report"]) is BugReport)
}

///|
test "completions: with shell" {
  match parse_args(["completions", "zsh"]) {
    Completions(shell) => assert_eq(shell, "zsh")
    _ => fail("Expected Completions")
  }
}

///|
test "completions: no shell shows help" {
  assert_true(parse_args(["completions"]) is Help)
}

///|
test "session" {
  assert_true(parse_args(["session"]) is Session)
}

///|
test "prompt: --pipestatus" {
  let cmd = parse_args(["prompt", "--pipestatus", "0 1 0"])
  match cmd {
    Prompt(pa) => {
      assert_eq(pa.pipestatus.length(), 3)
      assert_eq(pa.pipestatus[0], "0")
      assert_eq(pa.pipestatus[1], "1")
      assert_eq(pa.pipestatus[2], "0")
    }
    _ => fail("Expected Prompt")
  }
}

///|
test "prompt: --pipestatus empty" {
  let cmd = parse_args(["prompt", "--pipestatus", ""])
  match cmd {
    Prompt(pa) => assert_eq(pa.pipestatus.length(), 0)
    _ => fail("Expected Prompt")
  }
}

///|
test "explain: default" {
  match parse_args(["explain"]) {
    Explain(pa) => assert_eq(pa.status, 0)
    _ => fail("Expected Explain")
  }
}

///|
test "explain: with options" {
  match parse_args(["explain", "--status", "1"]) {
    Explain(pa) => assert_eq(pa.status, 1)
    _ => fail("Expected Explain")
  }
}

///|
test "prompt: --logical-path" {
  let cmd = parse_args(["prompt", "--logical-path", "/virtual/path"])
  match cmd {
    Prompt(pa) => assert_eq(pa.logical_path, "/virtual/path")
    _ => fail("Expected Prompt")
  }
}

///|
test "prompt: -P short flag" {
  let cmd = parse_args(["prompt", "-P", "/virtual/path"])
  match cmd {
    Prompt(pa) => assert_eq(pa.logical_path, "/virtual/path")
    _ => fail("Expected Prompt")
  }
}

///|
test "prompt: no pipestatus defaults to empty" {
  let cmd = parse_args(["prompt"])
  match cmd {
    Prompt(pa) => assert_eq(pa.pipestatus.length(), 0)
    _ => fail("Expected Prompt")
  }
}
