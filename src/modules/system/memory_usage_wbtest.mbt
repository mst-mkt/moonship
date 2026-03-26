///|
async test "name" {
  let m : &@ms.PromptModule = MemoryUsageModule::default()
  assert_eq(m.name(), "memory_usage")
}

///|
async test "execute: disabled by default" {
  let m = MemoryUsageModule::default()
  let ctx = @context.Context::new(cwd="/tmp")
  assert_true(m.execute(ctx) is Disabled)
}

///|
test "parse_meminfo: standard" {
  let content =
    #|MemTotal:       16384000 kB
    #|MemFree:         2048000 kB
    #|MemAvailable:    8192000 kB
    #|Buffers:          512000 kB
  let (total, available) = parse_meminfo(content)
  assert_true(total > 0L)
  assert_true(available > 0L)
  assert_true(total > available)
}

///|
test "parse_meminfo: empty" {
  let (total, available) = parse_meminfo("")
  assert_eq(total, 0L)
  assert_eq(available, 0L)
}

///|
test "format_bytes: gib" {
  assert_eq(format_bytes(1073741824L), "1.0GiB")
}

///|
test "format_bytes: mib" {
  assert_eq(format_bytes(536870912L), "512MiB")
}

///|
test "parse_kb_value: standard" {
  assert_eq(parse_kb_value("MemTotal:       16384000 kB"), 16384000L)
}
