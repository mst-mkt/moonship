///|
async test "name" {
  let m : &@ms.PromptModule = HgStateModule::default()
  assert_eq(m.name(), "hg_state")
}

///|
async test "execute: disabled by default" {
  let m = HgStateModule::default()
  let ctx = @context.Context::new(cwd="/tmp")
  assert_true(m.execute(ctx) is Disabled)
}
