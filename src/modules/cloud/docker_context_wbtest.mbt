///|
async test "name" {
  let m : &@ms.PromptModule = DockerContextModule::default()
  assert_eq(m.name(), "docker_context")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[docker_context]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = DockerContextModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no docker files returns Skipped" {
  let path = "/tmp/moonship-test-docker-empty"
  @test_util.setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = DockerContextModule::default()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects Dockerfile" {
  let path = "/tmp/moonship-test-docker-file"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/Dockerfile", "")
  let m = DockerContextModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no Docker files detected")) else {
    fail("expected Dockerfile to be detected, but got Skipped")
  }
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects compose.yml" {
  let path = "/tmp/moonship-test-docker-compose"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/compose.yml", "")
  let m = DockerContextModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no Docker files detected")) else {
    fail("expected compose.yml to be detected, but got Skipped")
  }
  @test_util.remove_dir_recursive(path)
}

///|
test "parse_docker_config_context: valid" {
  let json =
    #|{
    #|  "currentContext": "my-context",
    #|  "other": "value"
    #|}
  assert_eq(parse_docker_config_context(json), "my-context")
}

///|
test "parse_docker_config_context: no context" {
  let json =
    #|{
    #|  "other": "value"
    #|}
  assert_eq(parse_docker_config_context(json), "")
}

///|
test "parse_docker_config_context: empty" {
  assert_eq(parse_docker_config_context(""), "")
}

///|
test "is_default_context: default" {
  assert_true(is_default_context("default"))
}

///|
test "is_default_context: desktop-linux" {
  assert_true(is_default_context("desktop-linux"))
}

///|
test "is_default_context: unix prefix" {
  assert_true(is_default_context("unix:///var/run/docker.sock"))
}

///|
test "is_default_context: custom" {
  assert_false(is_default_context("my-context"))
}
