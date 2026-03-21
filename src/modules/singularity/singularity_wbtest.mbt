///|
async test "name" {
  let m : &@ms.PromptModule = SingularityModule::new()
  assert_eq(m.name(), "singularity")
}

///|
async test "execute: not in singularity returns Skipped" {
  let m = SingularityModule::new()
  let ctx = @context.Context::new(cwd="/tmp")
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
}
