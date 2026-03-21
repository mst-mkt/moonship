///|
pub struct LocalipModule {
  disabled : Bool
  format : String
  style : String
  ssh_only : Bool
}

///|
pub fn LocalipModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module(
    "localip",
  ),
) -> LocalipModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    ssh_only: config.get_prop("ssh_only", default="true") == "true",
  }
}

///|
pub fn LocalipModule::from_config(config : @config.Config) -> LocalipModule {
  LocalipModule::new(config=config.get_module("localip"))
}

///|
pub impl @ms.PromptModule for LocalipModule with name(_self) -> String {
  "localip"
}

///|
pub impl @ms.PromptModule for LocalipModule with execute(
  self,
  _ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }

  if self.ssh_only {
    let ssh = @sys.get_env_var("SSH_CONNECTION").unwrap_or("")
    guard not(ssh.is_empty()) else { return Skipped("not in SSH session") }
  }

  let ip = get_local_ip()
  guard not(ip.is_empty()) else { return Skipped("could not get local IP") }

  let vars : Map[String, String] = { "localipv4": ip, "style": self.style }
  let segments = @ms.format_string(
    self.format,
    vars,
    @terminal.Style::default(),
  )

  Output(@ms.ModuleOutput::new(segments))
}

///|
fn get_local_ip() -> String {
  // Connect UDP socket to 192.0.2.0:80 (reserved, no packets sent)
  // and read back the local address. Same approach as starship.
  let target = @socket.Addr::new(0xC0000200U, 80)
  let client = @socket.UdpClient::new(target) catch { _ => return "" }

  let local_addr = client.addr()
  client.close()

  let s = local_addr.to_string()

  // Strip the port suffix (:port)
  match s.find(":") {
    Some(idx) => s[:idx].to_string()
    None => s
  }
}
