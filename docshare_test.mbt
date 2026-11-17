///|
fn fixture() -> @docshare.DocShare raise @fga.FgaError {
  @docshare.DocShare::from_json(
    (
      #|[
      #|  {"object":"group:team","relation":"member","user":"user:member"},
      #|  {"object":"folder:shared","relation":"editor","user":"group:team#member"},
      #|  {"object":"folder:shared","relation":"viewer","user":"user:reader"},
      #|  {"object":"document:guide","relation":"parent","user":"folder:shared"},
      #|  {"object":"document:notes","relation":"parent","user":"folder:shared"},
      #|  {"object":"document:temporary","relation":"viewer","user":"user:guest",
      #|   "condition":{"name":"before_expiry","context":{"expires_at":"2030-01-02T00:00:00Z"}}}
      #|]
    ),
  )
}

///|
test "folder viewer inherits view but cannot edit" {
  let service = fixture()
  assert_true(
    service.can_view("user:reader", "document:guide", "2030-01-01T00:00:00Z"),
  )
  assert_false(service.can_edit("user:reader", "document:guide"))
}

///|
test "group membership inherits edit and view through the parent" {
  let service = fixture()
  assert_true(service.can_edit("user:member", "document:guide"))
  assert_true(
    service.can_view("user:member", "document:guide", "2030-01-01T00:00:00Z"),
  )
}

///|
test "CEL conditional view allows before expiry and denies at or after expiry" {
  let service = fixture()
  assert_true(
    service.can_view("user:guest", "document:temporary", "2030-01-01T00:00:00Z"),
  )
  assert_false(
    service.can_view("user:guest", "document:temporary", "2030-01-02T00:00:00Z"),
  )
  assert_false(
    service.can_view("user:guest", "document:temporary", "2030-01-03T00:00:00Z"),
  )
  assert_false(service.can_edit("user:guest", "document:temporary"))
}

///|
test "unrelated subject and absent document are denied" {
  let service = fixture()
  assert_false(
    service.can_view("user:outsider", "document:guide", "2030-01-01T00:00:00Z"),
  )
  assert_false(service.can_edit("user:outsider", "document:guide"))
  assert_false(
    service.can_view("user:reader", "document:absent", "2030-01-01T00:00:00Z"),
  )
}

///|
test "ListObjects returns sorted inherited documents and filters expired access" {
  let service = fixture()
  @debug.assert_eq(
    service.list_viewable_documents("user:reader", "2030-01-01T00:00:00Z"),
    ["document:guide", "document:notes"],
  )
  @debug.assert_eq(
    service.list_viewable_documents("user:guest", "2030-01-01T00:00:00Z"),
    ["document:temporary"],
  )
  @debug.assert_eq(
    service.list_viewable_documents("user:guest", "2030-01-02T00:00:00Z"),
    [],
  )
  @debug.assert_eq(
    service.list_viewable_documents("user:outsider", "2030-01-01T00:00:00Z"),
    [],
  )
}

///|
test "sharing roles updates the live engine and duplicate writes are idempotent" {
  let service = @docshare.DocShare::new()
  assert_true(
    service.share_document("document:view", "user:reader", @docshare.Viewer),
  )
  assert_false(
    service.share_document("document:view", "user:reader", @docshare.Viewer),
  )
  assert_true(
    service.share_document("document:edit", "user:reader", @docshare.Editor),
  )
  assert_true(
    service.share_document("document:own", "user:reader", @docshare.Owner),
  )
  assert_true(
    service.can_view("user:reader", "document:view", "2030-01-01T00:00:00Z"),
  )
  assert_false(service.can_edit("user:reader", "document:view"))
  assert_true(service.can_edit("user:reader", "document:edit"))
  assert_true(service.can_edit("user:reader", "document:own"))
  @debug.assert_eq(
    service.list_viewable_documents("user:reader", "2030-01-01T00:00:00Z"),
    ["document:edit", "document:own", "document:view"],
  )
}

///|
test "invalid provisioning is rejected without granting access" {
  let service = @docshare.DocShare::new()
  let rejected = try {
    let _ = service.share_document(
      "document:private",
      "group:team#member",
      @docshare.Owner,
    )
    false
  } catch {
    _ => true
  }
  assert_true(rejected)
  assert_false(
    service.can_view(
      "user:outsider", "document:private", "2030-01-01T00:00:00Z",
    ),
  )
  for
    source in [
      "null", "{}", "broken", "[{\"object\":\"document:x\",\"relation\":\"unknown\",\"user\":\"user:reader\"}]",
    ] {
    let rejected = try {
      let _ = @docshare.DocShare::from_json(source)
      false
    } catch {
      _ => true
    }
    assert_true(rejected)
  }
}

///|
test "invalid timestamp propagates as an error rather than a false authorization result" {
  let service = fixture()
  let rejected = try {
    let _ = service.can_view("user:guest", "document:temporary", "invalid")
    false
  } catch {
    _ => true
  }
  assert_true(rejected)
}
