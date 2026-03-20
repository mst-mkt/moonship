///|
async test "name" {
  let m : &@ms.PromptModule = MavenModule::new()
  assert_eq(m.name(), "maven")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[maven]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = MavenModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-maven-empty"
  setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = MavenModule::new()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  remove_dir_recursive(path)
}

///|
async test "execute: detects pom.xml" {
  let path = "/tmp/moonship-test-maven-pom"
  setup_dir(path)
  @fs.write_string_to_file(path + "/pom.xml", "")
  let m = MavenModule::new()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  assert_false(result is Skipped("no Maven project detected"))
  remove_dir_recursive(path)
}

///|
test "parse_maven_wrapper_version: standard" {
  let content =
    #|distributionUrl=https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/3.9.12/apache-maven-3.9.12-bin.zip
  assert_eq(parse_maven_wrapper_version(content), "3.9.12")
}

///|
test "parse_maven_wrapper_version: empty" {
  assert_eq(parse_maven_wrapper_version(""), "")
}

///|
test "parse_maven_wrapper_version: no url" {
  assert_eq(parse_maven_wrapper_version("some=other"), "")
}

///|
test "extract_maven_version: standard" {
  assert_eq(
    extract_maven_version(
      "distributionUrl=https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/3.9.12/apache-maven-3.9.12-bin.zip",
    ),
    "3.9.12",
  )
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
