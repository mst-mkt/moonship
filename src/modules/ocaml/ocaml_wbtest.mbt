///|
async test "name" {
  let m : &@ms.PromptModule = OCamlModule::default()
  assert_eq(m.name(), "ocaml")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[ocaml]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = OCamlModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-ocaml-empty"
  @test_util.setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = OCamlModule::default()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects dune" {
  let path = "/tmp/moonship-test-ocaml-dune"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/dune", "")
  let m = OCamlModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no OCaml project detected"))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .ml extension" {
  let path = "/tmp/moonship-test-ocaml-ml"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/main.ml", "")
  let m = OCamlModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no OCaml project detected"))
  @test_util.remove_dir_recursive(path)
}

///|
test "parse_opam_switch: global" {
  let (indicator, name) = parse_opam_switch(
    "ocaml-base-compiler.4.10.0", "", "*",
  )
  assert_eq(indicator, "")
  assert_eq(name, "ocaml-base-compiler.4.10.0")
}

///|
test "parse_opam_switch: local" {
  let (indicator, name) = parse_opam_switch("/path/to/my-project", "", "*")
  assert_eq(indicator, "*")
  assert_eq(name, "my-project")
}

///|
test "parse_opam_switch: custom indicators" {
  let (indicator, name) = parse_opam_switch(
    "ocaml-base-compiler.4.10.0", "g/", "^",
  )
  assert_eq(indicator, "g/")
  assert_eq(name, "ocaml-base-compiler.4.10.0")
}


