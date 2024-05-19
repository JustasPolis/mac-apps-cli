import ArgumentParser

struct App: ParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "MacOS apps CLI tool",
    subcommands: [List.self, Open.self]
  )
}
