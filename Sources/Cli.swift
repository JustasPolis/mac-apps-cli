import ArgumentParser

@main
struct Cli: ParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "MacOS apps CLI tool",
    subcommands: [List.self, Open.self]
  )
}
