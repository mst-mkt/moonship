///|
async test "name" {
  let m : &@ms.PromptModule = NatsModule::new()
  assert_eq(m.name(), "nats")
}

///|
async test "execute: disabled by default" {
  let m = NatsModule::new()
  let ctx = @context.Context::new(cwd="/tmp")
  assert_true(m.execute(ctx) is Disabled)
}

///|
test "parse_nats_context_name: valid" {
  let json =
    #|{"name": "my-context", "url": "nats://localhost:4222"}
  assert_eq(parse_nats_context_name(json), "my-context")
}

///|
test "parse_nats_context_name: empty" {
  assert_eq(parse_nats_context_name(""), "")
}
