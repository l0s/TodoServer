import Foundation
import Kitura
import LoggerAPI
import Configuration
import CloudEnvironment
import KituraContracts
import Health
import KituraOpenAPI
import KituraCORS
import Dispatch

public let projectPath = ConfigurationManager.BasePath.project.path
public let health = Health()

public class App {
    let router = Router()
    let cloudEnv = CloudEnv()

    internal var todoStore: [ToDo] = []
    internal var nextId: Int = 0
    private let workerQueue = DispatchQueue(label: "worker")

    public init() throws {
        // Run the metrics initializer
        initializeMetrics(router: router)
    }

    func postInit() throws {
        // enable CORS
        let options = Options( allowedOrigin: .all )
        let cors = CORS( options: options )
        router.all( "/*", middleware: cors )

        // Endpoints
        initializeHealthRoutes(app: self)
        router.post( "/", handler: handleStore )

        KituraOpenAPI.addEndpoints( to: router )
    }

    public func run() throws {
        try postInit()
        Kitura.addHTTPServer(onPort: cloudEnv.port, with: router)
        Kitura.run()
    }

    internal func execute( _ block: ( () -> Void ) ) {
        workerQueue.sync(execute: block)
    }

    internal func handleStore( input: ToDo, completion: ( ToDo?, RequestError? ) -> Void ) {
        var todo = input // create mutable copy
        execute {
            let id = nextId
            nextId = nextId + 1

            if todo.completed == nil {
                todo.completed = false
            }
            todo.id = id
            todo.url = "http://localhost:8080/\(id)"
            todoStore.append( todo )
        }
        completion( todo, nil )
    }

}
