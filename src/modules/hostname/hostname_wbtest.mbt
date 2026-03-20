///|
test "name" {
  let m : &@ms.PromptModule = HostnameModule::new()
  assert_eq(m.name(), "hostname")
}

// --- execute ---

///|
test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[hostname]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = HostnameModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
test "execute: ssh_only skips without SSH" {
  let ctx = @context.Context::new(cwd="/tmp")
  let m = HostnameModule::new()

  // Default ssh_only=true, not in SSH → Skipped
  assert_true(m.execute(ctx) is Skipped(_))
}

// --- trim_hostname ---

///|
test "trim_hostname: trims at dot" {
  assert_eq(trim_hostname("host.example.com", "."), "host")
}

///|
test "trim_hostname: no dot returns unchanged" {
  assert_eq(trim_hostname("myhost", "."), "myhost")
}

///|
test "trim_hostname: empty trim_at returns unchanged" {
  assert_eq(trim_hostname("host.example.com", ""), "host.example.com")
}

///|
test "trim_hostname: custom trim_at" {
  assert_eq(trim_hostname("host-region-az", "-"), "host")
}
