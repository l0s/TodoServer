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
        router.post( "/", handler: store )
        router.delete( "/", handler: deleteAll )
        router.get( "/", handler: getAll )
        router.get( "/", handler: findById )
        router.patch( "/", handler: update )
        router.delete( "/", handler: deleteById )

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

    internal func store( input: ToDo, completion: ( ToDo?, RequestError? ) -> Void ) {
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

    internal func deleteAll( completion: ( RequestError? ) -> Void ) {
        execute {
            todoStore = []
        }
        completion( nil )
    }

    internal func getAll( completion: ( [ ToDo ]?, RequestError? ) -> Void ) {
        completion( todoStore, nil )
    }

    internal func findById( id: Int, completion: ( ToDo?, RequestError? ) -> Void ) {
        guard let todo = todoStore.first( where: { $0.id == id } ) else {
            completion( nil, .notFound )
            return
        }
        completion( todo, nil )
    }

    internal func update( id: Int, todo: ToDo, completion: ( ToDo?, RequestError? ) -> Void ) {
        guard let index = todoStore.index(where: { $0.id == id }) else {
            completion( nil, .notFound )
            return
        }
        var item = todoStore[ index ]
        item.user = todo.user ?? item.user
        item.order = todo.order ?? item.order
        item.title = todo.title ?? item.title
        item.completed = todo.completed ?? item.completed
        execute {
            todoStore[ index ] = item
        }
        completion( item, nil )
    }

    internal func deleteById( id: Int, completion: ( RequestError? ) -> Void ) {
        guard let index = todoStore.index(where: { $0.id == id }) else {
            completion( .notFound )
            return
        }
        execute {
            todoStore.remove(at: index)
        }
        completion( nil )
    }

}
