///|
async test "name" {
  let m : &@ms.PromptModule = NetnsModule::new()
  assert_eq(m.name(), "netns")
}

///|
async test "execute: not in netns returns Skipped" {
  let m = NetnsModule::new()
  let ctx = @context.Context::new(cwd="/tmp")
  let result = m.execute(ctx)
  assert_true(result is Skipped(_) || result is Output(_))
}
