///|
async test "name" {
  let m : &@ms.PromptModule = OpenstackModule::default()
  assert_eq(m.name(), "openstack")
}

///|
async test "execute: no OS_CLOUD returns Skipped" {
  let m = OpenstackModule::default()
  let ctx = @context.Context::new(cwd="/tmp")
  let result = m.execute(ctx)
  assert_true(not(result is Disabled))
}
