///|
async test "name" {
  let m : &@ms.PromptModule = FossilBranchModule::default()
  assert_eq(m.name(), "fossil_branch")
}

///|
async test "execute: disabled by default" {
  let m = FossilBranchModule::default()
  let ctx = @context.Context::new(cwd="/tmp")
  assert_true(m.execute(ctx) is Disabled)
}
