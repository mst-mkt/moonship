///|
async test "name" {
  let m : &@ms.PromptModule = FossilBranchModule::new()
  assert_eq(m.name(), "fossil_branch")
}

///|
async test "execute: disabled by default" {
  let m = FossilBranchModule::new()
  let ctx = @context.Context::new(cwd="/tmp")
  assert_true(m.execute(ctx) is Disabled)
}
