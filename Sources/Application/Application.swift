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
import SwiftKueryORM
import SwiftKueryPostgreSQL

public let projectPath = ConfigurationManager.BasePath.project.path
public let health = Health()

public class App {
    let router = Router()
    let cloudEnv = CloudEnv()

    internal var nextId: Int = 0
    private let workerQueue = DispatchQueue(label: "worker")

    public init() throws {
        // Run the metrics initializer
        initializeMetrics(router: router)
    }

    func postInit() throws {
        // setup database
        Persistence.setUp()
        do {
            try ToDo.createTableSync()
        } catch let error {
            print("Table already exists. Error: \(String(describing: error))")
        }
        
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

    internal func store( input: ToDo, completion: @escaping ( ToDo?, RequestError? ) -> Void ) {
        var todo = input // create mutable copy
        execute {
            // FIXME use sequence or UUID
            let id = nextId
            nextId = nextId + 1
            
            if todo.completed == nil {
                todo.completed = false
            }
            todo.id = id
            todo.url = "http://localhost:8080/\(id)"
            todo.save( completion )
        }
    }

    internal func deleteAll( completion: @escaping ( RequestError? ) -> Void ) {
        ToDo.deleteAll( completion )
    }

    internal func getAll( completion: @escaping ( [ ToDo ]?, RequestError? ) -> Void ) {
        ToDo.findAll( completion )
    }

    internal func findById( id: Int, completion: @escaping ( ToDo?, RequestError? ) -> Void ) {
        ToDo.find(id: id, completion )
    }

    internal func update( id: Int, todo: ToDo, completion: @escaping ( ToDo?, RequestError? ) -> Void ) {
        ToDo.find( id: id ) { ( existing, error ) in
            if let error = error {
                completion( nil, .notFound )
                return
            }
            guard var item = existing else {
                completion( nil, .notFound )
                return
            }
            guard let id = item.id else {
                completion( nil, .internalServerError )
                return
            }

            item.user = todo.user ?? item.user
            item.order = todo.order ?? item.order
            item.title = todo.title ?? item.title
            item.completed = todo.completed ?? item.completed

            item.update( id: id, completion )
        }
    }

    internal func deleteById( id: Int, completion: @escaping ( RequestError? ) -> Void ) {
        ToDo.delete(id: id, completion)
    }

}

extension ToDo: Model {
    
}

class Persistence {
    static func setUp() {
        let pool =
            PostgreSQLConnection.createPool(host: "localhost",
                                            port: 5432,
                                            options: [.databaseName("tododb")],
                                            poolOptions: ConnectionPoolOptions(initialCapacity: 10,
                                                                               maxCapacity: 50,
                                                                               timeout: 10000))
        Database.default = Database(pool)
    }
}
