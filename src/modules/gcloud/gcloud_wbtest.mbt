///|
async test "name" {
  let m : &@ms.PromptModule = GcloudModule::default()
  assert_eq(m.name(), "gcloud")
}

///|
async test "execute: no gcloud config returns Skipped or Output" {
  let m = GcloudModule::default()
  let ctx = @context.Context::new(cwd="/tmp")
  let result = m.execute(ctx)
  assert_true(result is Skipped(_) || result is Output(_))
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[gcloud]
      #|disabled = true
    ),
  )
  let m = GcloudModule::from_config(config)
  let ctx = @context.Context::new(cwd="/tmp", config~)
  assert_true(m.execute(ctx) is Disabled)
}

///|
test "get_ini_value: core account" {
  let content =
    #|[core]
    #|account = user@example.com
    #|project = my-project
    #|
    #|[compute]
    #|region = us-central1
  assert_eq(get_ini_value(content, "core", "account"), "user@example.com")
}

///|
test "get_ini_value: compute region" {
  let content =
    #|[core]
    #|account = user@example.com
    #|
    #|[compute]
    #|region = asia-northeast1
  assert_eq(get_ini_value(content, "compute", "region"), "asia-northeast1")
}

///|
test "get_ini_value: missing section" {
  let content =
    #|[core]
    #|account = user@example.com
  assert_eq(get_ini_value(content, "compute", "region"), "")
}

///|
test "get_ini_value: missing key" {
  let content =
    #|[core]
    #|account = user@example.com
  assert_eq(get_ini_value(content, "core", "project"), "")
}

///|
test "get_ini_value: empty" {
  assert_eq(get_ini_value("", "core", "account"), "")
}
