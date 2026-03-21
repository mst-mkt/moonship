///|
pub struct DirenvModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  allowed_msg : String
  not_allowed_msg : String
  denied_msg : String
  loaded_msg : String
  unloaded_msg : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn DirenvModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module(
    "direnv",
  ),
) -> DirenvModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="direnv "),
    allowed_msg: config.get_prop("allowed_msg", default="allowed"),
    not_allowed_msg: config.get_prop("not_allowed_msg", default="not allowed"),
    denied_msg: config.get_prop("denied_msg", default="denied"),
    loaded_msg: config.get_prop("loaded_msg", default="loaded"),
    unloaded_msg: config.get_prop("unloaded_msg", default="not loaded"),
    detect_files: [".envrc"],
    detect_extensions: [],
  }
}

///|
pub fn DirenvModule::from_config(config : @config.Config) -> DirenvModule {
  DirenvModule::new(config=config.get_module("direnv"))
}

///|
pub impl @ms.PromptModule for DirenvModule with name(_self) -> String {
  "direnv"
}

///|
pub impl @ms.PromptModule for DirenvModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }

  let has_env = not(@sys.get_env_var("DIRENV_FILE").unwrap_or("").is_empty())
  guard has_env ||
    @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no direnv detected")
  }

  let output = @exec.exec_cmd_full("direnv", ["status"])
  let (loaded, allowed) = parse_direnv_status(output)

  let loaded_str = if loaded { self.loaded_msg } else { self.unloaded_msg }
  let allowed_str = match allowed {
    "allowed" => self.allowed_msg
    "denied" => self.denied_msg
    _ => self.not_allowed_msg
  }

  let vars : Map[String, String] = {
    "symbol": self.symbol,
    "loaded": loaded_str,
    "allowed": allowed_str,
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
fn parse_direnv_status(output : String) -> (Bool, String) {
  let lines = output.split("\n").collect()
  let mut loaded = false
  let mut allowed = "not_allowed"

  for line in lines {
    let s = line.to_string()

    if s.contains("No .envrc") || s.contains("No .env") {
      loaded = false
    } else if s.contains("Found RC") || s.contains("Loaded RC") {
      loaded = true

      if s.contains("allowed 0") || s.contains("allowed true") {
        allowed = "allowed"
      } else if s.contains("allowed 2") || s.contains("allowed false") {
        allowed = "denied"
      } else if s.contains("allowed 1") {
        allowed = "not_allowed"
      }
    }
  }

  (loaded, allowed)
}
