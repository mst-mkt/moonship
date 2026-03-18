///|
test "prompt: オプション付き" {
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
test "prompt: デフォルト値" {
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
test "version / help" {
  assert_true(parse_args(["version"]) is Version)
  assert_true(parse_args(["--version"]) is Version)
  assert_true(parse_args(["-V"]) is Version)
  assert_true(parse_args(["help"]) is Help)
  assert_true(parse_args(["--help"]) is Help)
  assert_true(parse_args(["-h"]) is Help)
}

///|
test "引数なしは Help" {
  assert_true(parse_args([]) is Help)
}

///|
test "不明なコマンド" {
  match parse_args(["foo"]) {
    UnknownCommand(name) => assert_eq(name, "foo")
    _ => fail("Expected UnknownCommand")
  }
}

///|
test "フラグ: 正常" {
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
test "フラグ: 不正" {
  assert_true(extract_flag_value("status=0") is None)
  assert_true(extract_flag_value("--status") is None)
  assert_true(extract_flag_value("") is None)
}

///|
test "整数パース" {
  assert_eq(parse_int_arg("42"), 42)
  assert_eq(parse_int_arg("-1"), -1)
  assert_eq(parse_int_arg("abc"), 0)
  assert_eq(parse_int_arg(""), 0)
}

///|
test "prompt: 全オプション" {
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
test "prompt: 不正な値はデフォルト" {
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
test "prompt: 未知のフラグは無視" {
  let cmd = parse_args(["prompt", "--unknown=value", "--status=5"])
  match cmd {
    Prompt(pa) => assert_eq(pa.status, 5)
    _ => fail("Expected Prompt")
  }
}
