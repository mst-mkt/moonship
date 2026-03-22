///|
async test "name" {
  let m : &@ms.PromptModule = ScalaModule::default()
  assert_eq(m.name(), "scala")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[scala]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = ScalaModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-scala-empty"
  setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = ScalaModule::default()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  remove_dir_recursive(path)
}

///|
async test "execute: detects build.sbt" {
  let path = "/tmp/moonship-test-scala-sbt"
  setup_dir(path)
  @fs.write_string_to_file(path + "/build.sbt", "")
  let m = ScalaModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Scala project detected"))
  remove_dir_recursive(path)
}

///|
async test "execute: detects .scala extension" {
  let path = "/tmp/moonship-test-scala-ext"
  setup_dir(path)
  @fs.write_string_to_file(path + "/Main.scala", "")
  let m = ScalaModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Scala project detected"))
  remove_dir_recursive(path)
}

///|
async test "execute: detects .scalaenv" {
  let path = "/tmp/moonship-test-scala-env"
  setup_dir(path)
  @fs.write_string_to_file(path + "/.scalaenv", "")
  let m = ScalaModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Scala project detected"))
  remove_dir_recursive(path)
}

///|
test "parse_scalac_version: scala 2" {
  assert_eq(
    parse_scalac_version("Scala compiler version 2.13.5 -- Copyright"),
    "2.13.5",
  )
}

///|
test "parse_scalac_version: scala 3" {
  assert_eq(
    parse_scalac_version("Scala compiler version 3.0.0-RC1 -- Copyright"),
    "3.0.0-RC1",
  )
}

///|
test "parse_scalac_version: empty" {
  assert_eq(parse_scalac_version(""), "")
}

///|
test "parse_scalac_version: too few words" {
  assert_eq(parse_scalac_version("Scala compiler version"), "")
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
