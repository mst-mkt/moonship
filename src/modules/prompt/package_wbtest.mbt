///|
async test "name" {
  let m : &@ms.PromptModule = PackageModule::default()
  assert_eq(m.name(), "package")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[package]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = PackageModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no package file returns Skipped" {
  let ctx = @context.Context::new(cwd="/tmp")
  let m = PackageModule::default()
  assert_true(m.execute(ctx) is Skipped(_))
}

///|
async test "detect_version: package.json" {
  let path = "/tmp/moonship-test-package-json"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/package.json", "{\"version\": \"3.0.0\"}")

  assert_eq(detect_version(path), "3.0.0")

  @test_util.remove_dir_recursive(path)
}

///|
async test "detect_version: Cargo.toml" {
  let path = "/tmp/moonship-test-package-cargo"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(
    path + "/Cargo.toml",
    "[package]\nversion = \"0.5.0\"",
  )

  assert_eq(detect_version(path), "0.5.0")

  @test_util.remove_dir_recursive(path)
}

///|
async test "detect_version: pubspec.yaml" {
  let path = "/tmp/moonship-test-package-pubspec"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(
    path + "/pubspec.yaml",
    "name: myapp\nversion: 1.2.3\n",
  )

  assert_eq(detect_version(path), "1.2.3")

  @test_util.remove_dir_recursive(path)
}

///|
async test "detect_version: pom.xml" {
  let path = "/tmp/moonship-test-package-pom"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(
    path + "/pom.xml",
    "<project><version>4.0.0</version></project>",
  )

  assert_eq(detect_version(path), "4.0.0")

  @test_util.remove_dir_recursive(path)
}

///|
async test "detect_version: jsr.json" {
  let path = "/tmp/moonship-test-package-jsr"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/jsr.json", "{\"version\": \"0.9.0\"}")

  assert_eq(detect_version(path), "0.9.0")

  @test_util.remove_dir_recursive(path)
}

///|
async test "detect_version: daml.yaml" {
  let path = "/tmp/moonship-test-package-daml"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/daml.yaml", "version: 1.5.0\n")

  assert_eq(detect_version(path), "1.5.0")

  @test_util.remove_dir_recursive(path)
}

///|
async test "detect_version: DESCRIPTION (R)" {
  let path = "/tmp/moonship-test-package-r"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(
    path + "/DESCRIPTION",
    "Package: mypkg\nVersion: 0.8.0\n",
  )

  assert_eq(detect_version(path), "0.8.0")

  @test_util.remove_dir_recursive(path)
}

///|
async test "detect_version: nimble" {
  let path = "/tmp/moonship-test-package-nimble"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/myproject.nimble", "version = \"0.2.0\"\n")

  assert_eq(detect_version(path), "0.2.0")

  @test_util.remove_dir_recursive(path)
}

///|
async test "detect_version: no package file" {
  let path = "/tmp/moonship-test-package-empty"
  @test_util.setup_dir(path)

  assert_eq(detect_version(path), "")

  @test_util.remove_dir_recursive(path)
}

///|
async test "detect_version: priority order" {
  let path = "/tmp/moonship-test-package-priority"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/package.json", "{\"version\": \"1.0.0\"}")
  @fs.write_string_to_file(
    path + "/Cargo.toml",
    "[package]\nversion = \"2.0.0\"",
  )

  assert_eq(detect_version(path), "1.0.0")

  @test_util.remove_dir_recursive(path)
}

// --- display_private ---

///|
test "is_private_package: private true" {
  let path = "/tmp/moonship-test-pkg-private"
  @fs.create_dir(path) catch {
    _ => ()
  }
  @fs.write_string_to_file(
    path + "/package.json",
    "{\"name\": \"test\", \"version\": \"1.0.0\", \"private\": true}",
  )

  assert_true(is_private_package(path))

  @fs.remove_file(path + "/package.json") catch {
    _ => ()
  }
  @fs.remove_dir(path) catch {
    _ => ()
  }
}

///|
test "is_private_package: not private" {
  let path = "/tmp/moonship-test-pkg-public"
  @fs.create_dir(path) catch {
    _ => ()
  }
  @fs.write_string_to_file(
    path + "/package.json",
    "{\"name\": \"test\", \"version\": \"1.0.0\"}",
  )

  assert_false(is_private_package(path))

  @fs.remove_file(path + "/package.json") catch {
    _ => ()
  }
  @fs.remove_dir(path) catch {
    _ => ()
  }
}

///|
test "is_private_package: no package.json" {
  assert_false(is_private_package("/tmp"))
}

///|
async test "execute: private package skipped by default" {
  let path = "/tmp/moonship-test-pkg-skip-private"
  @fs.create_dir(path) catch {
    _ => ()
  }
  @fs.write_string_to_file(
    path + "/package.json",
    "{\"name\": \"test\", \"version\": \"1.0.0\", \"private\": true}",
  )

  let m = PackageModule::default()
  let ctx = @context.Context::new(cwd=path)
  assert_true(m.execute(ctx) is Skipped(_))

  @fs.remove_file(path + "/package.json") catch {
    _ => ()
  }
  @fs.remove_dir(path) catch {
    _ => ()
  }
}

// --- version_format ---

///|
test "from_table: version_format parsed" {
  let config = @config.Config::from_toml(
    (
      #|[package]
      #|version_format = "${major}.${minor}"
    ),
  )
  let m = PackageModule::from_config(config)
  assert_eq(m.version_format, "${major}.${minor}")
}

///|
test "from_table: version_format defaults to v${raw}" {
  let m = PackageModule::default()
  assert_eq(m.version_format, "v${raw}")
}

///|
async test "execute: version_format applied to output" {
  let path = "/tmp/moonship-test-pkg-vfmt"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/package.json", "{\"version\": \"1.2.3\"}")

  let config = @config.Config::from_toml(
    (
      #|[package]
      #|version_format = "${major}.${minor}"
    ),
  )
  let m = PackageModule::from_config(config)
  let ctx = @context.Context::new(cwd=path, config~)

  guard m.execute(ctx) is Output(out) else {
    @test_util.remove_dir_recursive(path)
    fail("expected Output")
    return
  }

  let rendered = out.render()
  assert_true(rendered.contains("1.2"))
  assert_false(rendered.contains("1.2.3"))

  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: default version_format adds v prefix" {
  let path = "/tmp/moonship-test-pkg-vprefix"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/package.json", "{\"version\": \"2.0.0\"}")

  let m = PackageModule::default()
  let ctx = @context.Context::new(cwd=path)

  guard m.execute(ctx) is Output(out) else {
    @test_util.remove_dir_recursive(path)
    fail("expected Output")
    return
  }

  assert_true(out.render().contains("v2.0.0"))

  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: version_format raw passthrough" {
  let path = "/tmp/moonship-test-pkg-raw"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/package.json", "{\"version\": \"3.1.4\"}")

  let config = @config.Config::from_toml(
    (
      #|[package]
      #|version_format = "${raw}"
    ),
  )
  let m = PackageModule::from_config(config)
  let ctx = @context.Context::new(cwd=path, config~)

  guard m.execute(ctx) is Output(out) else {
    @test_util.remove_dir_recursive(path)
    fail("expected Output")
    return
  }

  assert_true(out.render().contains("3.1.4"))

  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: private package shown when display_private=true" {
  let path = "/tmp/moonship-test-pkg-show-private"
  @fs.create_dir(path) catch {
    _ => ()
  }
  @fs.write_string_to_file(
    path + "/package.json",
    "{\"name\": \"test\", \"version\": \"1.0.0\", \"private\": true}",
  )

  let config = @config.Config::from_toml(
    (
      #|[package]
      #|display_private = true
    ),
  )
  let m = PackageModule::from_config(config)
  let ctx = @context.Context::new(cwd=path, config~)

  guard m.execute(ctx) is Output(out) else {
    @fs.remove_file(path + "/package.json") catch {
      _ => ()
    }
    @fs.remove_dir(path) catch {
      _ => ()
    }
    fail("expected Output")
    return
  }

  assert_true(out.render().contains("1.0.0"))

  @fs.remove_file(path + "/package.json") catch {
    _ => ()
  }
  @fs.remove_dir(path) catch {
    _ => ()
  }
}
