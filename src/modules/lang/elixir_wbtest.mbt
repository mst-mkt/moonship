///|
async test "name" {
  let m : &@ms.PromptModule = ElixirModule::default()
  assert_eq(m.name(), "elixir")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[elixir]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = ElixirModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-elixir-empty"
  @test_util.setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = ElixirModule::default()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects mix.exs" {
  let path = "/tmp/moonship-test-elixir-mix"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/mix.exs", "")
  let m = ElixirModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no Elixir project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
test "parse_elixir_version: stable" {
  let input =
    #|Erlang/OTP 23 [erts-11.1.7] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:1]
    #|
    #|Elixir 1.11.3 (compiled with Erlang/OTP 21)
  let (elixir, otp) = parse_elixir_version(input)
  assert_eq(elixir, "1.11.3")
  assert_eq(otp, "23")
}

///|
test "parse_elixir_version: rc" {
  let input =
    #|Erlang/OTP 23 [erts-11.1.7] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:1]
    #|
    #|Elixir 1.12.0-rc.0 (31d2b99) (compiled with Erlang/OTP 21)
  let (elixir, otp) = parse_elixir_version(input)
  assert_eq(elixir, "1.12.0-rc.0")
  assert_eq(otp, "23")
}

///|
test "parse_elixir_version: dev" {
  let input =
    #|Erlang/OTP 23 [erts-11.1.7] [source] [64-bit] [smp:8:8] [ds:8:8:10] [async-threads:1]
    #|
    #|Elixir 1.13.0-dev (compiled with Erlang/OTP 23)
  let (elixir, otp) = parse_elixir_version(input)
  assert_eq(elixir, "1.13.0-dev")
  assert_eq(otp, "23")
}

///|
test "parse_elixir_version: otp only" {
  let input = "Erlang/OTP 25 [erts-13.0] [source] [64-bit]"
  let (elixir, otp) = parse_elixir_version(input)
  assert_eq(elixir, "")
  assert_eq(otp, "25")
}

///|
test "parse_elixir_version: elixir only" {
  let input = "Elixir 1.14.0 (compiled with Erlang/OTP 25)"
  let (elixir, otp) = parse_elixir_version(input)
  assert_eq(elixir, "1.14.0")
  assert_eq(otp, "")
}

///|
test "parse_elixir_version: empty" {
  let (elixir, otp) = parse_elixir_version("")
  assert_eq(elixir, "")
  assert_eq(otp, "")
}

///|
test "parse_elixir_version: unexpected format" {
  let (elixir, otp) = parse_elixir_version("something unexpected")
  assert_eq(elixir, "")
  assert_eq(otp, "")
}
