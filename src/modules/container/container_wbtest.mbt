///|
async test "name" {
  let m : &@ms.PromptModule = ContainerModule::default()
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

///|
test "parse_containerenv_name: image with registry path" {
  assert_eq(
    parse_containerenv_name(
      "image=\"registry.fedoraproject.org/fedora-toolbox:35\"",
    ),
    "fedora-toolbox:35",
  )
}

///|
test "parse_containerenv_name: image without registry path" {
  assert_eq(parse_containerenv_name("image=\"ubuntu:22.04\""), "ubuntu:22.04")
}

///|
test "parse_containerenv_name: unquoted image with registry path" {
  assert_eq(
    parse_containerenv_name(
      "image=registry.fedoraproject.org/fedora-toolbox:35",
    ),
    "fedora-toolbox:35",
  )
}

///|
test "strip_registry_path: with slashes" {
  assert_eq(strip_registry_path("a/b/c"), "c")
}

///|
test "strip_registry_path: no slashes" {
  assert_eq(strip_registry_path("my-image"), "my-image")
}
