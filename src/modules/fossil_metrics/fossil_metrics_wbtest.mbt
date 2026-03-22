///|
async test "name" {
  let m : &@ms.PromptModule = FossilMetricsModule::default()
  assert_eq(m.name(), "fossil_metrics")
}

///|
async test "execute: disabled by default" {
  let m = FossilMetricsModule::default()
  let ctx = @context.Context::new(cwd="/tmp")
  assert_true(m.execute(ctx) is Disabled)
}

///|
test "parse_fossil_numstat: standard" {
  let output =
    #|   3   1 src/main.c
    #|   5   2 src/util.c
    #|   8   3 TOTAL over 2 changed files
  let (added, deleted) = parse_fossil_numstat(output)
  assert_eq(added, 8)
  assert_eq(deleted, 3)
}

///|
test "parse_fossil_numstat: empty" {
  let (added, deleted) = parse_fossil_numstat("")
  assert_eq(added, 0)
  assert_eq(deleted, 0)
}
