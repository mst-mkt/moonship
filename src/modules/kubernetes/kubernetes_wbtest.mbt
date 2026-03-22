///|
async test "name" {
  let m : &@ms.PromptModule = KubernetesModule::default()
  assert_eq(m.name(), "kubernetes")
}

///|
async test "execute: disabled by default" {
  let m = KubernetesModule::default()
  let ctx = @context.Context::new(cwd="/tmp")
  assert_true(m.execute(ctx) is Disabled)
}
