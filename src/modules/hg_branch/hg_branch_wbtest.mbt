///|
async test "name" {
  let m : &@ms.PromptModule = HgBranchModule::new()
  assert_eq(m.name(), "hg_branch")
}

///|
async test "execute: disabled by default" {
  let m = HgBranchModule::new()
  let ctx = @context.Context::new(cwd="/tmp")
  assert_true(m.execute(ctx) is Disabled)
}
