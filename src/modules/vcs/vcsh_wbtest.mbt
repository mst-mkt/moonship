///|
async test "name" {
  let m : &@ms.PromptModule = VcshModule::default()
  assert_eq(m.name(), "vcsh")
}

///|
async test "execute: not in vcsh returns Skipped" {
  let m = VcshModule::default()
  let ctx = @context.Context::new(cwd="/tmp")
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
}
