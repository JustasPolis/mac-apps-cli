import ArgumentParser

@main
struct Cli: ParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "A Swift command-line tool with multiple commands.",
    subcommands: [Apps.self, Open.self]
  )

  init() {}
}
