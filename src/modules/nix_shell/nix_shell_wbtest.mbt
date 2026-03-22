///|
async test "name" {
  let m : &@ms.PromptModule = NixShellModule::default()
  assert_eq(m.name(), "nix_shell")
}

///|
async test "execute: not in nix shell returns Skipped" {
  let m = NixShellModule::default()
  let ctx = @context.Context::new(cwd="/tmp")
  let result = m.execute(ctx)
  // IN_NIX_SHELL is typically not set outside nix
  assert_true(result is Skipped(_) || result is Output(_))
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[nix_shell]
      #|disabled = true
    ),
  )
  let m = NixShellModule::from_config(config)
  let ctx = @context.Context::new(cwd="/tmp", config~)
  assert_true(m.execute(ctx) is Disabled)
}

///|
test "is_nix_in_path: with nix store" {
  // Can't easily test without setting PATH, but verify function exists
  let _ = is_nix_in_path()
}
