///|
test "parse_json_version: valid" {
  assert_eq(parse_json_version("{\"version\": \"1.2.3\"}"), "1.2.3")
}

///|
test "parse_json_version: no version" {
  assert_eq(parse_json_version("{\"name\": \"foo\"}"), "")
}

///|
test "parse_json_version: invalid" {
  assert_eq(parse_json_version("not json"), "")
}

///|
test "parse_cargo_toml: valid" {
  assert_eq(
    parse_cargo_toml(
      (
        #|[package]
        #|version = "0.1.0"
      ),
    ),
    "0.1.0",
  )
}

///|
test "parse_cargo_toml: no package section" {
  assert_eq(
    parse_cargo_toml(
      (
        #|[dependencies]
        #|serde = "1.0"
      ),
    ),
    "",
  )
}

///|
test "parse_pyproject_toml: valid" {
  assert_eq(
    parse_pyproject_toml(
      (
        #|[project]
        #|version = "2.0.0"
      ),
    ),
    "2.0.0",
  )
}

///|
test "parse_julia_toml: root version" {
  assert_eq(
    parse_julia_toml(
      (
        #|name = "MyPackage"
        #|version = "0.3.0"
      ),
    ),
    "0.3.0",
  )
}

///|
test "extract_version_line: yaml style" {
  assert_eq(extract_version_line("name: foo\nversion: 1.0.0\n"), "1.0.0")
}

///|
test "extract_version_line: gradle style" {
  assert_eq(extract_version_line("version = \"3.2.1\"\n"), "3.2.1")
}

///|
test "extract_version_line: sbt style" {
  assert_eq(extract_version_line("version := \"0.1.0\"\n"), "0.1.0")
}

///|
test "extract_version_line: single quotes" {
  assert_eq(extract_version_line("version: '2.0.0'\n"), "2.0.0")
}

///|
test "extract_version_line: mix.exs style" {
  assert_eq(extract_version_line("  version: \"0.4.0\",\n"), "0.4.0")
}

///|
test "extract_version_line: no version" {
  assert_eq(extract_version_line("name: foo\n"), "")
}

///|
test "extract_version_line: version in value is ignored" {
  assert_eq(
    extract_version_line(
      "description = A library for version control\nversion = 1.0.0\n",
    ),
    "1.0.0",
  )
}

///|
test "strip_quotes: double quotes" {
  assert_eq(strip_quotes(" \"1.0.0\" "), "1.0.0")
}

///|
test "strip_quotes: single quotes" {
  assert_eq(strip_quotes(" '2.0.0' "), "2.0.0")
}

///|
test "strip_quotes: no quotes" {
  assert_eq(strip_quotes(" 3.0.0 "), "3.0.0")
}

///|
test "strip_quotes: trailing comma" {
  assert_eq(strip_quotes(" \"1.0.0\","), "1.0.0")
}

///|
test "parse_r_description: valid" {
  assert_eq(
    parse_r_description("Package: mypackage\nVersion: 1.3.0\nTitle: Test\n"),
    "1.3.0",
  )
}

///|
test "parse_r_description: no version" {
  assert_eq(parse_r_description("Package: mypackage\nTitle: Test\n"), "")
}

///|
test "extract_xml_version: valid" {
  assert_eq(
    extract_xml_version("<project><version>1.0.0</version></project>"),
    "1.0.0",
  )
}

///|
test "extract_xml_version: no version tag" {
  assert_eq(extract_xml_version("<project><name>foo</name></project>"), "")
}

// --- edge cases ---

///|
test "parse_json_version: empty string" {
  assert_eq(parse_json_version(""), "")
}

///|
test "parse_json_version: no version field" {
  assert_eq(parse_json_version("{\"name\": \"test\"}"), "")
}

///|
test "parse_json_version: malformed JSON" {
  assert_eq(parse_json_version("{broken"), "")
}

///|
test "extract_xml_version: empty content" {
  assert_eq(extract_xml_version(""), "")
}

///|
test "extract_xml_version: missing version tag" {
  assert_eq(extract_xml_version("<name>test</name>"), "")
}

///|
test "extract_xml_version: unclosed tag" {
  assert_eq(extract_xml_version("<version>1.0"), "")
}

///|
test "extract_xml_version: nested tags" {
  assert_eq(
    extract_xml_version("<parent><version>1.0</version></parent>"),
    "1.0",
  )
}

///|
test "parse_r_description: empty" {
  assert_eq(parse_r_description(""), "")
}

///|
test "parse_r_description: no Version line" {
  assert_eq(parse_r_description("Title: My Package\nAuthor: Someone"), "")
}

///|
test "strip_quotes: all quotes" {
  assert_eq(strip_quotes("\"'hello'\""), "hello")
}

///|
test "strip_quotes: empty string" {
  assert_eq(strip_quotes(""), "")
}

///|
test "extract_version_line: no separator" {
  assert_eq(extract_version_line("version 1.0"), "")
}

///|
test "extract_version_line: multiple versions picks first" {
  assert_eq(extract_version_line("version = 1.0\nversion = 2.0"), "1.0")
}

///|
test "extract_toml_version: empty content" {
  assert_eq(extract_toml_version("", path=["version"]), "")
}

///|
test "extract_toml_version: invalid TOML" {
  assert_eq(extract_toml_version("[invalid", path=["version"]), "")
}

///|
test "find_file_with_extension: nonexistent dir" {
  assert_eq(find_file_with_extension("/nonexistent/dir/abc123", ".txt"), "")
}
