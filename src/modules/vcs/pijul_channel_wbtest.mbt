///|
async test "name" {
  let m : &@ms.PromptModule = PijulChannelModule::default()
  assert_eq(m.name(), "pijul_channel")
}

///|
async test "execute: disabled by default" {
  let m = PijulChannelModule::default()
  let ctx = @context.Context::new(cwd="/tmp")
  assert_true(m.execute(ctx) is Disabled)
}

///|
test "parse_pijul_channel: active channel" {
  let output =
    #|  main
    #|* develop
    #|  feature
  assert_eq(parse_pijul_channel(output), "develop")
}

///|
test "parse_pijul_channel: empty" {
  assert_eq(parse_pijul_channel(""), "")
}
