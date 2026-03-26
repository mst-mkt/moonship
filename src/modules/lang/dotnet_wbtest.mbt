///|
async test "name" {
  let m : &@ms.PromptModule = DotnetModule::default()
  assert_eq(m.name(), "dotnet")
}

///|
async test "execute: disabled returns Disabled" {
  let config = @config.Config::from_toml(
    (
      #|[dotnet]
      #|disabled = true
    ),
  )
  let ctx = @context.Context::new(cwd="/tmp", config~)
  let m = DotnetModule::from_config(config)
  assert_true(m.execute(ctx) is Disabled)
}

///|
async test "execute: no project returns Skipped" {
  let path = "/tmp/moonship-test-dotnet-empty"
  @test_util.setup_dir(path)
  let ctx = @context.Context::new(cwd=path)
  let m = DotnetModule::default()
  let result = m.execute(ctx)
  assert_true(result is Skipped(_))
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects global.json" {
  let path = "/tmp/moonship-test-dotnet-global"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/global.json", "")
  let m = DotnetModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no .NET project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .csproj extension" {
  let path = "/tmp/moonship-test-dotnet-csproj"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/app.csproj", "")
  let m = DotnetModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no .NET project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects Directory.Build.props" {
  let path = "/tmp/moonship-test-dotnet-props"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/Directory.Build.props", "")
  let m = DotnetModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no .NET project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
async test "execute: detects .fsproj extension" {
  let path = "/tmp/moonship-test-dotnet-fsproj"
  @test_util.setup_dir(path)
  @fs.write_string_to_file(path + "/app.fsproj", "")
  let m = DotnetModule::default()
  let ctx = @context.Context::new(cwd=path)
  let result = m.execute(ctx)
  guard not(result is Skipped("no .NET project detected")) else {
    fail("project should be detected")
  }
  if result is Output(out) {
    assert_true(out.render().contains("via"))
  }
  @test_util.remove_dir_recursive(path)
}

///|
test "extract_tfm: TargetFramework" {
  let csproj =
    #|<Project Sdk="Microsoft.NET.Sdk">
    #|  <PropertyGroup>
    #|    <TargetFramework>net8.0</TargetFramework>
    #|  </PropertyGroup>
    #|</Project>
  assert_eq(extract_tfm(csproj), "net8.0")
}

///|
test "extract_tfm: TargetFrameworks plural" {
  let csproj =
    #|<Project Sdk="Microsoft.NET.Sdk">
    #|  <PropertyGroup>
    #|    <TargetFrameworks>netstandard2.0;net461</TargetFrameworks>
    #|  </PropertyGroup>
    #|</Project>
  assert_eq(extract_tfm(csproj), "netstandard2.0;net461")
}

///|
test "extract_tfm: empty" {
  assert_eq(extract_tfm(""), "")
}

///|
test "extract_tfm: no tfm tag" {
  let csproj =
    #|<Project Sdk="Microsoft.NET.Sdk">
    #|  <PropertyGroup>
    #|    <OutputType>Exe</OutputType>
    #|  </PropertyGroup>
    #|</Project>
  assert_eq(extract_tfm(csproj), "")
}
