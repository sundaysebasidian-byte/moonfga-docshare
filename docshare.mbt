///|
pub(all) enum Role {
  Viewer
  Editor
  Owner
}

///|
pub struct DocShare {
  priv model : @fga.AuthModel
  priv tuples : @store.MemoryStore
  priv engine : @engine.Engine
}

///|
pub fn model_source() -> String {
  let source =
    #|model
    #|  schema 1.1
    #|
    #|type user
    #|
    #|type group
    #|  relations
    #|    define member: [user]
    #|
    #|type folder
    #|  relations
    #|    define owner: [user]
    #|    define editor: [user, group#member] or owner
    #|    define viewer: [user, group#member] or editor
    #|
    #|type document
    #|  relations
    #|    define parent: [folder]
    #|    define owner: [user]
    #|    define editor: [user, group#member] or owner or editor from parent
    #|    define viewer: [user, group#member, user with before_expiry] or editor or viewer from parent
    #|
    #|condition before_expiry(now: timestamp, expires_at: timestamp) {
    #|  now < expires_at
    #|}
  source
}

///|
fn invalid(message : String) -> @fga.FgaError {
  @fga.fail(@fga.ERR_VALIDATION, message)
}

///|
fn validate_tuple(
  model : @fga.AuthModel,
  tuple : @fga.Tuple,
) -> Unit raise @fga.FgaError {
  if !@fga.is_valid_object(tuple.object) || !@fga.is_valid_user(tuple.user) {
    raise invalid("invalid object or subject")
  }
  let restrictions = model.direct_restrictions(
    @fga.object_type(tuple.object),
    tuple.relation,
  )
  let matching = restrictions.filter(fn(restriction) {
    restriction.condition == tuple.condition_name()
  })
  if !@fga.restrictions_allow(matching, tuple.user) {
    raise invalid("tuple is not allowed by the document-sharing model")
  }
}

///|
/// Input is a JSON array of MoonFGA tuple objects, with optional conditions.
pub fn DocShare::from_json(source : String) -> DocShare raise @fga.FgaError {
  let json = @json.parse(source) catch {
    _ => raise invalid("invalid tuples JSON")
  }
  guard json is Array(_) else { raise invalid("tuples must be a JSON array") }
  let model = @dsl.parse_model(model_source())
  @validate.validate_or_fail(model)
  let tuples = @fga.tuples_from_json(Some(json))
  for tuple in tuples {
    validate_tuple(model, tuple)
  }
  let store = @store.MemoryStore::new()
  let _ = store.write_all(tuples)
  {
    model,
    tuples: store,
    engine: @engine.Engine::new(model, store as &@fga.TupleReader),
  }
}

///|
pub fn DocShare::new() -> DocShare raise @fga.FgaError {
  DocShare::from_json("[]")
}

///|
/// Trusted provisioning operation; the caller must authorize mutations.
pub fn DocShare::share_document(
  self : DocShare,
  document : String,
  subject : String,
  role : Role,
) -> Bool raise @fga.FgaError {
  if @fga.object_type(document) != "document" {
    raise invalid("expected a document object")
  }
  let tuple = @fga.Tuple::{
    object: document,
    relation: match role {
      Viewer => "viewer"
      Editor => "editor"
      Owner => "owner"
    },
    user: subject,
    condition: None,
  }
  validate_tuple(self.model, tuple)
  self.tuples.write(tuple)
}

///|
fn request_context(now : String) -> Map[String, @json.Json] {
  Map([("now", @json.Json::string(now))])
}

///|
/// `now` must come from a trusted host clock in a real service.
pub fn DocShare::can_view(
  self : DocShare,
  user : String,
  document : String,
  now : String,
) -> Bool raise @fga.FgaError {
  self.engine.check_with(document, "viewer", user, request_context(now), [])
}

///|
pub fn DocShare::can_edit(
  self : DocShare,
  user : String,
  document : String,
) -> Bool raise @fga.FgaError {
  self.engine.check(document, "editor", user)
}

///|
pub fn DocShare::list_viewable_documents(
  self : DocShare,
  user : String,
  now : String,
) -> Array[String] raise @fga.FgaError {
  let documents = self.engine.list_objects(
    "document",
    "viewer",
    user,
    request_context(now),
    [],
  )
  documents.sort_by(String::lexical_compare)
  documents
}
