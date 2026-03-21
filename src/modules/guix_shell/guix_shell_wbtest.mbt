///|
async test "name" {
  let m : &@ms.PromptModule = GuixShellModule::new()
  assert_eq(m.name(), "guix_shell")
}

///|
async test "execute: not in guix returns Skipped" {
  let m = GuixShellModule::new()
  let ctx = @context.Context::new(cwd="/tmp")
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
}
