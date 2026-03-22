///|
async test "name" {
  let m : &@ms.PromptModule = LuaModule::default()
  assert_eq(m.name(), "lua")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[lua]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = LuaModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-lua-empty"
  setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = LuaModule::default()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  remove_dir_recursive(path)
}

///|
async test "execute: detects .lua-version" {
  let path = "/tmp/moonship-test-lua-version"
  setup_dir(path)
  @fs.write_string_to_file(path + "/.lua-version", "")
  let m = LuaModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Lua project detected"))
  remove_dir_recursive(path)
}

///|
async test "execute: detects .lua extension" {
  let path = "/tmp/moonship-test-lua-ext"
  setup_dir(path)
  @fs.write_string_to_file(path + "/main.lua", "")
  let m = LuaModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Lua project detected"))
  remove_dir_recursive(path)
}

///|
test "parse_lua_version: standard" {
  assert_eq(
    parse_lua_version("Lua 5.4.0  Copyright (C) 1994-2020 Lua.org, PUC-Rio"),
    "5.4.0",
  )
}

///|
test "parse_lua_version: luajit" {
  assert_eq(
    parse_lua_version(
      "LuaJIT 2.1.0-beta3 -- Copyright (C) 2005-2017 Mike Pall. http://luajit.org/",
    ),
    "2.1.0-beta3",
  )
}

///|
test "parse_lua_version: empty" {
  assert_eq(parse_lua_version(""), "")
}

///|
test "parse_lua_version: single word" {
  assert_eq(parse_lua_version("Lua"), "")
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
