import ArgumentParser

struct Open: ParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Process a command with either an ID or a path."
  )

  @Option(name: .shortAndLong, help: "The ID of window")
  var id: Int?

  @Option(name: .shortAndLong, help: "The path to executable.")
  var path: String?

  func validate() throws {
    guard id != nil || path != nil else {
      throw ValidationError("You must provide either --id or --path.")
    }
    guard !(id != nil && path != nil) else {
      throw ValidationError("You can provide only one of --id or --path.")
    }
  }

  func run() throws {
    if let id = id {
      print("Processing with ID: \(id)")
    } else if let path = path {
      print("Processing with path: \(path)")
    }
  }
}
