///|
pub struct ErlangModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn ErlangModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module(
    "erlang",
  ),
) -> ErlangModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default=" "),
    detect_files: ["rebar.config", "erlang.mk"],
    detect_extensions: [],
  }
}

///|
pub fn ErlangModule::from_config(config : @config.Config) -> ErlangModule {
  ErlangModule::new(config=config.get_module("erlang"))
}

///|
pub impl @ms.PromptModule for ErlangModule with name(_self) -> String {
  "erlang"
}

///|
pub impl @ms.PromptModule for ErlangModule with is_async(_self) -> Bool {
  false
}

///|
pub impl @ms.PromptModule for ErlangModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no Erlang project detected")
  }

  let version = @exec.exec_cmd("erl", [
    "-noshell", "-eval", "Fn=filename:join([code:root_dir(),\"releases\",erlang:system_info(otp_release),\"OTP_VERSION\"]),{ok,Content}=file:read_file(Fn),io:format(\"~s\",[Content]),halt(0).",
  ])
  guard not(version.is_empty()) else { return Skipped("erl not found") }

  let vars : Map[String, String] = {
    "version": @exec.add_v_prefix(version),
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
