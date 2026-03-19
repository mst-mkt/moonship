///|
test "prompt: with options" {
  let cmd = parse_args(["prompt", "--status=1", "--cmd-duration=500"])
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
    "prompt", "--status=127", "--cmd-duration=1000", "--jobs=3", "--terminal-width=120",
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
test "prompt: invalid values fallback to default" {
  let cmd = parse_args(["prompt", "--status=abc", "--jobs=-"])
  match cmd {
    Prompt(pa) => {
      assert_eq(pa.status, 0)
      assert_eq(pa.jobs, 0)
    }
    _ => fail("Expected Prompt")
  }
}

///|
test "prompt: unknown flags ignored" {
  let cmd = parse_args(["prompt", "--unknown=value", "--status=5"])
  match cmd {
    Prompt(pa) => assert_eq(pa.status, 5)
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
  assert_true(parse_args(["print-config"]) is PrintConfig)
}

///|
test "init: with shell" {
  match parse_args(["init", "zsh"]) {
    Init(shell) => assert_eq(shell, "zsh")
    _ => fail("Expected Init")
  }
}

///|
test "init: no shell" {
  assert_true(parse_args(["init"]) is UnknownShell)
}

///|
test "time" {
  assert_true(parse_args(["time"]) is Time)
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
test "flag: valid" {
  match extract_flag_value("--status=0") {
    Some(("status", "0")) => ()
    _ => fail("Expected Some((status, 0))")
  }
  match extract_flag_value("--cmd-duration=500") {
    Some(("cmd-duration", "500")) => ()
    _ => fail("Expected Some((cmd-duration, 500))")
  }
}

///|
test "flag: invalid" {
  assert_true(extract_flag_value("status=0") is None)
  assert_true(extract_flag_value("--status") is None)
  assert_true(extract_flag_value("") is None)
}

///|
test "parse int" {
  assert_eq(parse_int_arg("42"), 42)
  assert_eq(parse_int_arg("-1"), -1)
  assert_eq(parse_int_arg("abc"), 0)
  assert_eq(parse_int_arg(""), 0)
}
