///|
pub fn wrap_for_shell(shell : String, s : String) -> String {
  if shell == "zsh" {
    wrap_ansi_for_zsh(s)
  } else {
    s
  }
}

///|
pub fn wrap_ansi_for_zsh(s : String) -> String {
  let buf = StringBuilder::new()
  let len = s.length()

  loop 0 {
    i =>
      if i >= len {
        break buf.to_string()
      } else if i + 1 < len &&
        s[i].unsafe_to_char() == '\u001b' &&
        s[i + 1].unsafe_to_char() == '[' {
        buf.write_string("%{\u001b[")
        let end = scan_until_m(s, i + 2, buf)
        buf.write_string("%}")
        continue end
      } else {
        buf.write_char(s[i].unsafe_to_char())
        continue i + 1
      }
  }
}

///|
fn scan_until_m(s : String, start : Int, buf : StringBuilder) -> Int {
  let len = s.length()

  loop start {
    i =>
      if i >= len {
        break i
      } else {
        let ch = s[i].unsafe_to_char()
        buf.write_char(ch)
        if ch == 'm' {
          break i + 1
        } else {
          continue i + 1
        }
      }
  }
}
