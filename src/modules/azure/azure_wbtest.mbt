///|
async test "name" {
  let m : &@ms.PromptModule = AzureModule::new()
  assert_eq(m.name(), "azure")
}

///|
async test "execute: disabled by default" {
  let m = AzureModule::new()
  let ctx = @context.Context::new(cwd="/tmp")
  assert_true(m.execute(ctx) is Disabled)
}

///|
test "parse_azure_subscription: valid" {
  let json =
    #|{
    #|  "subscriptions": [
    #|    {
    #|      "name": "My Subscription",
    #|      "isDefault": true
    #|    }
    #|  ]
    #|}
  assert_eq(parse_azure_subscription(json), "My Subscription")
}

///|
test "parse_azure_subscription: no default" {
  let json =
    #|{
    #|  "subscriptions": [
    #|    {
    #|      "name": "Sub1",
    #|      "isDefault": false
    #|    }
    #|  ]
    #|}
  assert_eq(parse_azure_subscription(json), "")
}

///|
test "parse_azure_subscription: multi subscription" {
  let json =
    #|{
    #|  "subscriptions": [
    #|    {
    #|      "name": "Sub1",
    #|      "isDefault": false
    #|    },
    #|    {
    #|      "name": "Sub2",
    #|      "isDefault": true
    #|    }
    #|  ]
    #|}
  assert_eq(parse_azure_subscription(json), "Sub2")
}

///|
test "parse_azure_subscription: empty" {
  assert_eq(parse_azure_subscription(""), "")
}

///|
test "extract_json_string_value: standard" {
  assert_eq(extract_json_string_value(": \"hello\""), "hello")
}

///|
test "extract_json_string_value: empty" {
  assert_eq(extract_json_string_value(""), "")
}
