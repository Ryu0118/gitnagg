import GitNaggCLI
import GitNaggKit
import Logging

/// Bootstraps logging and runs the root CLI command.
@main
struct GitNaggMain {
    static func main() async {
        bootstrapLogging(level: .info)
        await GitNaggCommand.main(nil)
    }
}
