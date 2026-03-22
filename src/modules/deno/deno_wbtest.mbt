///|
async test "name" {
  let m : &@ms.PromptModule = DenoModule::default()
  assert_eq(m.name(), "deno")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[deno]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = DenoModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-deno-empty"
  setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = DenoModule::default()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  remove_dir_recursive(path)
}

///|
async test "execute: detects deno.json" {
  let path = "/tmp/moonship-test-deno-json"
  setup_dir(path)
  @fs.write_string_to_file(path + "/deno.json", "")
  let m = DenoModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Deno project detected"))
  remove_dir_recursive(path)
}

///|
async test "execute: detects deno.jsonc" {
  let path = "/tmp/moonship-test-deno-jsonc"
  setup_dir(path)
  @fs.write_string_to_file(path + "/deno.jsonc", "")
  let m = DenoModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Deno project detected"))
  remove_dir_recursive(path)
}

///|
async test "execute: detects deno.lock" {
  let path = "/tmp/moonship-test-deno-lock"
  setup_dir(path)
  @fs.write_string_to_file(path + "/deno.lock", "")
  let m = DenoModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Deno project detected"))
  remove_dir_recursive(path)
}

///|
async test "execute: detects mod.ts" {
  let path = "/tmp/moonship-test-deno-modts"
  setup_dir(path)
  @fs.write_string_to_file(path + "/mod.ts", "")
  let m = DenoModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Deno project detected"))
  remove_dir_recursive(path)
}

///|
async test "execute: detects deps.ts" {
  let path = "/tmp/moonship-test-deno-depsts"
  setup_dir(path)
  @fs.write_string_to_file(path + "/deps.ts", "")
  let m = DenoModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Deno project detected"))
  remove_dir_recursive(path)
}

///|
async test "execute: detects mod.js" {
  let path = "/tmp/moonship-test-deno-modjs"
  setup_dir(path)
  @fs.write_string_to_file(path + "/mod.js", "")
  let m = DenoModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Deno project detected"))
  remove_dir_recursive(path)
}

///|
async test "execute: detects deps.js" {
  let path = "/tmp/moonship-test-deno-depsjs"
  setup_dir(path)
  @fs.write_string_to_file(path + "/deps.js", "")
  let m = DenoModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Deno project detected"))
  remove_dir_recursive(path)
}

///|
test "parse_deno_version: standard output" {
  assert_eq(parse_deno_version("deno 1.40.2"), "1.40.2")
}

///|
test "parse_deno_version: v2" {
  assert_eq(parse_deno_version("deno 2.0.0"), "2.0.0")
}

///|
test "parse_deno_version: empty" {
  assert_eq(parse_deno_version(""), "")
}

///|
test "parse_deno_version: single word" {
  assert_eq(parse_deno_version("deno"), "")
}

///|
fn setup_dir(path : String) -> Unit {
  remove_dir_recursive(path)
  @fs.create_dir(path) catch {
    _ => ()
  }
}

///|
fn remove_dir_recursive(path : String) -> Unit {
  if not(@fs.path_exists(path)) {
    return
  }

  let entries = @fs.read_dir(path) catch { _ => return }

  for entry in entries {
    let full = path + "/" + entry
    let is_dir = @fs.is_dir(full) catch { _ => false }

    if is_dir {
      remove_dir_recursive(full)
    } else {
      @fs.remove_file(full) catch {
        _ => ()
      }
    }
  }

  @fs.remove_dir(path) catch {
    _ => ()
  }
}
