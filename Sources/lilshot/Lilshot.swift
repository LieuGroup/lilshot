import ArgumentParser

@main
struct Lilshot: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "lilshot",
        abstract: "Capture macOS windows by fuzzy query or window ID.",
        subcommands: [ListCommand.self, CaptureCommand.self]
    )
}
