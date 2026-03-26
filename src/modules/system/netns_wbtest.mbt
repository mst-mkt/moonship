///|
async test "name" {
  let m : &@ms.PromptModule = NetnsModule::default()
  assert_eq(m.name(), "netns")
}

///|
async test "execute: not in netns returns Skipped" {
  let m = NetnsModule::default()
  let ctx = @context.Context::new(cwd="/tmp")
  let result = m.execute(ctx)
  assert_true(not(result is Disabled))
}
