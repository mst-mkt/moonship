///|
pub struct PerlModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn PerlModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module("perl"),
) -> PerlModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="🐪 "),
    detect_files: [
      "Makefile.PL", "Build.PL", "cpanfile", "cpanfile.snapshot", "META.json", "META.yml",
      ".perl-version",
    ],
    detect_extensions: [".pl", ".pm", ".pod"],
  }
}

///|
pub fn PerlModule::from_config(config : @config.Config) -> PerlModule {
  PerlModule::new(config=config.get_module("perl"))
}

///|
pub impl @ms.PromptModule for PerlModule with name(_self) -> String {
  "perl"
}

///|
pub impl @ms.PromptModule for PerlModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no Perl project detected")
  }

  let output = @exec.exec_cmd("perl", ["-e", "printf q{%vd},$^V"])
  guard not(output.is_empty()) else { return Skipped("perl not found") }

  let vars : Map[String, String] = {
    "version": output,
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
