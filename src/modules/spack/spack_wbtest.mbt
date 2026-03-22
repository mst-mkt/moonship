///|
async test "name" {
  let m : &@ms.PromptModule = SpackModule::default()
  assert_eq(m.name(), "spack")
}

///|
async test "execute: not in spack returns Skipped" {
  let m = SpackModule::default()
  let ctx = @context.Context::new(cwd="/tmp")
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
}

///|
test "basename: path" {
  assert_eq(basename("/home/user/spack-envs/myenv"), "myenv")
}

///|
test "basename: no slash" {
  assert_eq(basename("myenv"), "myenv")
}
