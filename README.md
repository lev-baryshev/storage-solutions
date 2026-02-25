# storage-solutions
useful, expressive and beautiful solutions for local persistent data storing
## grdb-based solution
high-performance storage engine with useful and intuitive sql-like interface

### initializing database:

```swift
final class UserStorage {

    private let database: GrdbStorage

    init?() {
        let sqlite: URL = folder/"UserStorage.sqlite"                              // path to database sqlite file
        let versions: [GrdbSchemaVersion] = [UserStorage.V01(), UserStorage.V02()] // migrations. (see schema version example below)
        guard let database: GrdbStorage = .init(sqlite, versions, config)          // (see config example below)
        else {
            return nil
        }
        self.database = database
    }
    
}
```
### database operations:

```swift
// load from database:
func load(user id: Int) async -> User? {
    await database.read {
        try $0.select(User.where(Column(Users.id) == id))
    } catch: {
        log(error: "[UsersStorage][load] \($0)")
    }
}

// save into database:
func save(_ account: BackendApi.Account) async {
    await database.write { database in
        let user: User = .construct(from: account)
        try database.save(user)
    } catch: { 
        log(error: "[UserStorage][save] \($0)") 
    }
}

// update:
func update(name user: User) async {
    await database.write {
        try $0.update(
            User.where(Column(User.id) == user.id), 
            set: [Column(User.name).set(to: user.name)]
        )
    } catch: {
        log(error: "[UserStorage][update] \($0)")
    }
}

// raw sql usage example:
func loadUser(_ id: Int) async -> User? {
    await database.read {
        try $0.select(sql: "SELECT * FROM \(User.tableName) WHERE \(Columns.id) = \(id.sqlLiteral)") // sqlLiteral is to avoid sql-injection
    } catch: {
        log(error: "[UsersStorage][load] \($0)")
    }
}

// subscribe to updates:
func keepInformed(about userId: Int) -> AnyPublisher<User?, Never> {
    database.keepInformed {
        try $0.select(User.where(Column(Users.id) == id))
    }
}

// delete from database
func delete(except ids: [Int]) async {
    await database.write {
        try $0.delete(User.where(Column(User.id).isAbsent(among: ids)))
    } catch: {
        log(error: "[UserStorage][delete] \($0)")
    }
}
```
### record mapping example:

```swift
extension User : GrdbRecord {

    let tableName: String = "users"
    
    func save(into row: inout PersistenceContainer) throws {
        row[Columns.id] = id
        row[Columns.name] = name
        row[Columns.locale] = locale?.identifier
        row[Columns.demo] = demo
    }
    
    static func load(from row: Row) throws -> User {
        let id: Int         = row[Columns.id]
        let name: String    = row[Columns.name]
        let locale: String? = row[Columns.locale]
        let demo: Bool?     = row[Columns.demo]
        return User(id, name, Locale(identifier: locale ?? "en"), demo)
    }

}
```
### config example:

```swift
var config: Configuration = .init()
    config.readonly = false
    config.foreignKeysEnabled = true
    config.label = "UserStorageConnection" // useful when your app opens multiple databases
    config.targetQueue = DispatchQueue(label: "UserStorageQueue")
    config.maximumReaderCount = 5  // (DatabasePool only)
```

### schema version example:

```swift
extension UserStorage {
    
    final class V01 : GrdbSchemaVersion {
        
        let id: String = "v01"
        
        let upgrade: (Database) throws -> Void = { database in
            try database.create(table: User.tableName) { table in
                let nilString: String? = nil
                
                table.column(Columns.id,     .integer).notNull().primaryKey()
                table.column(Columns.name,   .text).notNull()
                table.column(Columns.locale, .text).defaults(to: nilString)
            }
        }
                    
    }
    
    final class V02 : GrdbSchemaVersion {
    
        let id: String = "v02"
        
        let upgrade: (Database) throws -> Void = { database in
            try database.alter(table: User.tableName) { table in
                let nilBoolean: Bool? = nil
                
                table.add(column: Columns.demo, .boolean).defaults(to: nilBoolean)
            }
        }
    
    }
    
}

private final class Columns {
    static let id:     String = "id"
    static let name:   String = "name"
    static let locale: String = "locale"
    static let demo:   String = "demo"
}
```
