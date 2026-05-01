import GitNaggCLI
import GitNaggKit
import Logging

/// Bootstraps logging and runs the root CLI command.
@main
struct GitNaggMain {
    static func main() async {
        LoggingBootstrap.bootstrap(level: .info)
        await GitNaggCommand.main(nil)
    }
}
