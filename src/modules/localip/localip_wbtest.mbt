///|
async test "name" {
  let m : &@ms.PromptModule = LocalipModule::new()
  assert_eq(m.name(), "localip")
}

///|
async test "execute: disabled by default" {
  let m = LocalipModule::new()
  let ctx = @context.Context::new(cwd="/tmp")
  assert_true(m.execute(ctx) is Disabled)
}
