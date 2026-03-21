///|
async test "name" {
  let m : &@ms.PromptModule = ContainerModule::new()
  assert_eq(m.name(), "container")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[container]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = ContainerModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
test "parse_containerenv_name: with name" {
  assert_eq(
    parse_containerenv_name("name=\"my-container\"\nimage=\"ubuntu\""),
    "my-container",
  )
}

///|
test "parse_containerenv_name: with image only" {
  assert_eq(parse_containerenv_name("image=\"my-image\""), "my-image")
}

///|
test "parse_containerenv_name: empty" {
  assert_eq(parse_containerenv_name(""), "")
}

///|
test "parse_containerenv_name: no quotes" {
  assert_eq(parse_containerenv_name("name=my-container"), "my-container")
}
