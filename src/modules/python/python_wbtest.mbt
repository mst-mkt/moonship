///|
async test "name" {
  let m : &@ms.PromptModule = PythonModule::default()
  assert_eq(m.name(), "python")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[python]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = PythonModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-python-empty"
  setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = PythonModule::default()
  assert_true(m.execute(ctx) is Skipped(_))
  remove_dir_recursive(path)
}

///|
async test "execute: detects requirements.txt" {
  let path = "/tmp/moonship-test-python-requirements"
  setup_dir(path)
  @fs.write_string_to_file(path + "/requirements.txt", "")
  let m = PythonModule::default()
  let ctx = @context.Context::new(cwd=path)
  assert_true(m.execute(ctx) is Output(_))
  remove_dir_recursive(path)
}

///|
async test "execute: detects pyproject.toml" {
  let path = "/tmp/moonship-test-python-pyproject"
  setup_dir(path)
  @fs.write_string_to_file(path + "/pyproject.toml", "")
  let m = PythonModule::default()
  let ctx = @context.Context::new(cwd=path)
  assert_true(m.execute(ctx) is Output(_))
  remove_dir_recursive(path)
}

///|
async test "execute: detects .python-version" {
  let path = "/tmp/moonship-test-python-version-file"
  setup_dir(path)
  @fs.write_string_to_file(path + "/.python-version", "")
  let m = PythonModule::default()
  let ctx = @context.Context::new(cwd=path)
  assert_true(m.execute(ctx) is Output(_))
  remove_dir_recursive(path)
}

///|
async test "execute: detects Pipfile" {
  let path = "/tmp/moonship-test-python-pipfile"
  setup_dir(path)
  @fs.write_string_to_file(path + "/Pipfile", "")
  let m = PythonModule::default()
  let ctx = @context.Context::new(cwd=path)
  assert_true(m.execute(ctx) is Output(_))
  remove_dir_recursive(path)
}

///|
async test "execute: detects tox.ini" {
  let path = "/tmp/moonship-test-python-tox"
  setup_dir(path)
  @fs.write_string_to_file(path + "/tox.ini", "")
  let m = PythonModule::default()
  let ctx = @context.Context::new(cwd=path)
  assert_true(m.execute(ctx) is Output(_))
  remove_dir_recursive(path)
}

///|
async test "execute: detects setup.py" {
  let path = "/tmp/moonship-test-python-setup"
  setup_dir(path)
  @fs.write_string_to_file(path + "/setup.py", "")
  let m = PythonModule::default()
  let ctx = @context.Context::new(cwd=path)
  assert_true(m.execute(ctx) is Output(_))
  remove_dir_recursive(path)
}

///|
async test "execute: detects __init__.py" {
  let path = "/tmp/moonship-test-python-init"
  setup_dir(path)
  @fs.write_string_to_file(path + "/__init__.py", "")
  let m = PythonModule::default()
  let ctx = @context.Context::new(cwd=path)
  assert_true(m.execute(ctx) is Output(_))
  remove_dir_recursive(path)
}

///|
async test "execute: detects .py extension" {
  let path = "/tmp/moonship-test-python-ext"
  setup_dir(path)
  @fs.write_string_to_file(path + "/main.py", "")
  let m = PythonModule::default()
  let ctx = @context.Context::new(cwd=path)
  assert_true(m.execute(ctx) is Output(_))
  remove_dir_recursive(path)
}

///|
async test "execute: detects .ipynb extension" {
  let path = "/tmp/moonship-test-python-ipynb"
  setup_dir(path)
  @fs.write_string_to_file(path + "/notebook.ipynb", "")
  let m = PythonModule::default()
  let ctx = @context.Context::new(cwd=path)
  assert_true(m.execute(ctx) is Output(_))
  remove_dir_recursive(path)
}

///|
async test "execute: custom symbol from config" {
  let config = @config.Config::from_toml(
    (
      #|[python]
      #|symbol = "PY "
    ),
  )
  let path = "/tmp/moonship-test-python-custom"
  setup_dir(path)
  @fs.write_string_to_file(path + "/main.py", "")
  let m = PythonModule::from_config(config)
  let ctx = @context.Context::new(cwd=path, config~)
  assert_true(m.execute(ctx) is Output(_))
  remove_dir_recursive(path)
}

///|
test "parse_python_version: standard output" {
  assert_eq(parse_python_version("Python 3.11.2"), "3.11.2")
}

///|
test "parse_python_version: anaconda output" {
  assert_eq(parse_python_version("Python 3.6.10 :: Anaconda, Inc."), "3.6.10")
}

///|
test "parse_python_version: single word" {
  assert_eq(parse_python_version("3.11.2"), "3.11.2")
}

///|
test "parse_python_version: empty" {
  assert_eq(parse_python_version(""), "")
}

///|
test "basename: simple path" {
  assert_eq(@exec.basename("/home/user/project/.venv"), ".venv")
}

///|
test "basename: trailing slash" {
  assert_eq(@exec.basename("/home/user/project/.venv/"), ".venv")
}

///|
test "basename: no slash" {
  assert_eq(@exec.basename("venv"), "venv")
}

///|
test "basename: empty" {
  assert_eq(@exec.basename(""), "")
}

///|
test "parent_dir: simple path" {
  assert_eq(@exec.parent_dir("/home/user/project/.venv"), "/home/user/project")
}

///|
test "parent_dir: trailing slash" {
  assert_eq(@exec.parent_dir("/home/user/project/.venv/"), "/home/user/project")
}

///|
test "parent_dir: no slash" {
  assert_eq(@exec.parent_dir("venv"), "")
}

///|
test "parent_dir: root level" {
  assert_eq(@exec.parent_dir("/venv"), "")
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
