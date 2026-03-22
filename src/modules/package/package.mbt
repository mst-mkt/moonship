///|
pub struct PackageModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
}

///|
pub fn PackageModule::default() -> PackageModule {
  {
    disabled: false,
    async_render: false,
    format: "is [$symbol$version]($style) ",
    style: "208 bold",
    symbol: "📦 ",
  }
}

///|
pub fn PackageModule::from_toml_table(
  table : @config.ModuleTable,
) -> PackageModule {
  let d = PackageModule::default()
  {
    disabled: @config.get_toml_bool(table, "disabled").unwrap_or(d.disabled),
    async_render: @config.get_toml_bool(table, "async").unwrap_or(
      d.async_render,
    ),
    format: @config.get_toml_string(table, "format").unwrap_or(d.format),
    style: @config.get_toml_string(table, "style").unwrap_or(d.style),
    symbol: @config.get_toml_string(table, "symbol").unwrap_or(d.symbol),
  }
}

///|
pub fn PackageModule::from_config(config : @config.Config) -> PackageModule {
  match config.get_raw_module("package") {
    Some(table) => PackageModule::from_toml_table(table)
    None => PackageModule::default()
  }
}

///|
pub impl @ms.PromptModule for PackageModule with name(_self) -> String {
  "package"
}

///|
pub impl @ms.PromptModule for PackageModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for PackageModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }

  let version = detect_version(ctx.cwd)
  guard not(version.is_empty()) else { return Skipped("no package file found") }

  let vars : Map[String, String] = {
    "version": version,
    "symbol": self.symbol,
    "style": self.style,
  }
  let segments = @ms.format_string(
    self.format,
    vars,
    @terminal.Style::default(),
  )

  Output(@ms.ModuleOutput::new(segments))
}

///|
fn detect_version(cwd : String) -> String {
  let candidates : Array[(String, (String) -> String)] = [
    ("package.json", parse_json_version),
    ("composer.json", parse_json_version),
    ("deno.json", parse_json_version),
    ("deno.jsonc", parse_json_version),
    ("jsr.json", parse_json_version),
    ("jsr.jsonc", parse_json_version),
    ("vpkg.json", parse_json_version),
    ("moon.mod.json", parse_json_version),
    ("Cargo.toml", parse_cargo_toml),
    ("pyproject.toml", parse_pyproject_toml),
    ("Project.toml", parse_julia_toml),
    ("pubspec.yaml", extract_version_line),
    ("Chart.yaml", extract_version_line),
    ("daml.yaml", extract_version_line),
    ("galaxy.yml", extract_version_line),
    ("shard.yml", extract_version_line),
    ("mix.exs", extract_version_line),
    ("gradle.properties", extract_version_line),
    ("build.gradle", extract_version_line),
    ("build.gradle.kts", extract_version_line),
    ("build.sbt", extract_version_line),
    ("meson.build", extract_version_line),
    ("setup.cfg", extract_version_line),
    ("v.mod", extract_version_line),
    ("DESCRIPTION", parse_r_description),
    ("pom.xml", extract_xml_version),
  ]

  for pair in candidates {
    let (filename, parser) = pair
    let path = cwd + "/" + filename
    if @fs.path_exists(path) {
      let content = @fs.read_file_to_string(path) catch { _ => continue }
      let version = parser(content)
      if not(version.is_empty()) {
        return version
      }
    }
  }

  let nimble = find_file_with_extension(cwd, ".nimble")
  if not(nimble.is_empty()) {
    let content = @fs.read_file_to_string(nimble) catch { _ => return "" }
    let version = extract_version_line(content)
    if not(version.is_empty()) {
      return version
    }
  }

  ""
}

///|
pub fn PackageModule::schema() -> @config.ModuleSchema {
  let d = PackageModule::default()
  {
    name: "package",
    fields: [
      {
        name: "disabled",
        field_type: @config.FBool,
        default_value: d.disabled.to_string(),
      },
      { name: "format", field_type: @config.FString, default_value: d.format },
      { name: "style", field_type: @config.FString, default_value: d.style },
      { name: "symbol", field_type: @config.FString, default_value: d.symbol },
    ],
  }
}
