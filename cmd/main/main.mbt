///|
fn usage() -> @fga.FgaError {
  @fga.fail(
    @fga.ERR_VALIDATION,
    "usage: check <tuples.json> <user> <document> <view|edit> <now RFC3339> | list <tuples.json> <user> <now RFC3339>",
  )
}

///|
fn run(args : Array[String]) -> Unit raise @fga.FgaError {
  let valid = match args {
    ["check", _, _, _, "view" | "edit", _] => true
    ["list", _, _, _] => true
    _ => false
  }
  if !valid {
    raise usage()
  }
  let source = @fs.read_file_to_string(args[1]) catch {
    _ => raise @fga.fail(@fga.ERR_VALIDATION, "cannot read tuples file")
  }
  let service = @docshare.DocShare::from_json(source)
  if args[0] == "check" {
    let allowed = if args[4] == "view" {
      service.can_view(args[2], args[3], args[5])
    } else {
      service.can_edit(args[2], args[3])
    }
    println(allowed.to_string())
  } else {
    let documents = service.list_viewable_documents(args[2], args[3])
    println(@json.Json::array(documents.map(@json.Json::string)).stringify())
  }
}

///|
fn main {
  run(arguments()) catch {
    err => {
      println("error: " + @fga.error_message(err))
      @sys.exit(2)
    }
  }
}
