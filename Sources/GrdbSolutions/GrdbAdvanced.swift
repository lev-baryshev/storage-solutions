//
//  GrdbAdvanced.swift
//  StorageSolutions
//
//  Created by sugarbaron on 02.10.2022.
//

import GRDB

public extension Database {

    func insert(_ record: GrdbRecord) throws {
        var record: GrdbRecord = record
        try record.insert(self)
    }
    
    func save(_ record: GrdbRecord) throws {
        var record: GrdbRecord = record
        try record.save(self)
    }
    
    /*
     Query syntax example:
     database.background.write { database in
         try database.update(
             User.where(Column(User.id) == userId),
                  set: [Column(User.firstName).set(to: firstName)]
         )
     }
     */
    func update<Record:GrdbRecord>(_ query: Query<Record>, set assignments: [ColumnAssignment]) throws {
        try query.updateAll(self, assignments)
    }

    func select<Record:GrdbRecord>(_ query: Query<Record>) throws -> Record? {
        try query.fetchOne(self)
    }

    func select<Record:GrdbRecord>(_ query: Query<Record>) throws -> [Record] {
        try query.fetchAll(self)
    }

    func selectAll<Record:GrdbRecord>(_ type: Record.Type) throws -> [Record] {
        try Record.fetchAll(self)
    }
    
    func select<Record:GrdbRecord>(sql: String) throws -> Record? {
        try Record.fetchOne(self, sql: sql)
    }
    
    func select<Record:GrdbRecord>(sql: String) throws -> [Record] {
        try Record.fetchAll(self, sql: sql)
    }
    
    func select<T:DatabaseValueConvertible>(sql: String) throws -> T? {
        try T.fetchOne(self, sql: sql)
    }
    
    func select<T:DatabaseValueConvertible>(sql: String) throws -> [T] {
        try T.fetchAll(self, sql: sql)
    }

    func isThere<Record:GrdbRecord>(_ query: Query<Record>) throws -> Bool {
        try query.isEmpty(self) == false
    }
    
    func isThere<Record>(_: Record.Type, with id: Record.ID) throws -> Bool
    where Record:(GrdbRecord & Identifiable), Record.ID:DatabaseValueConvertible {
        try Record.exists(self, id: id)
    }

    func isThereNo<Record:GrdbRecord>(_ query: Query<Record>) throws -> Bool {
        try query.isEmpty(self)
    }
    
    func isThereNo<Record>(_: Record.Type, with id: Record.ID) throws -> Bool
    where Record:(GrdbRecord & Identifiable), Record.ID:DatabaseValueConvertible {
        try Record.exists(self, id: id) == false
    }

    func count<Record:GrdbRecord>(_ query: Query<Record>) throws -> Int {
        try query.fetchCount(self)
    }

    func countAll<Record:GrdbRecord>(_ type: Record.Type) throws -> Int {
        try Record.fetchCount(self)
    }

    func delete<Record:GrdbRecord>(_ query: Query<Record>) throws {
        try query.deleteAll(self)
    }

    func deleteAll<Record:GrdbRecord>(_ type: Record.Type) throws {
        try type.deleteAll(self)
    }

    typealias Query = GRDB.QueryInterfaceRequest

}

public extension GRDB.TableRecord {

    static func `where`(_ condition: some SQLSpecificExpressible) -> QueryInterfaceRequest<Self> {
        filter(condition)
    }

}

public extension Database.ColumnType {

    static var timeInterval: Database.ColumnType { .real }
    
    static var binary: Database.ColumnType { .blob }
    
    static var jsonBinary: Database.ColumnType { .blob }
    
    static var jsonString: Database.ColumnType { .text }

}

public extension GRDB.Column {
    
    /*
     usage example:
     try database.delete(User.where(Column(User.id).isAbsent(among: ids)))
     */
    func isAbsent(among collection: [some SQLExpressible]) -> SQLSpecificExpressible {
        collection.contains(self) == false
    }
    
    /*
     usage example:
     try database.delete(User.where(Column(User.id).isOne(of: ids)))
     */
    func isOne(of collection: [some SQLExpressible]) -> SQLSpecificExpressible {
        collection.contains(self)
    }
    
}

public extension DatabaseQueue {
    
    func read<T>(_ transaction: @escaping (Database) throws -> T, callback: @escaping (Result<T, Error>) -> Void) {
        asyncRead {
            do {
                let database: Database = try $0.access()
                let read: T = try transaction(database)
                callback(.success(read))
            } catch {
                callback(.failure(error))
            }
        }
    }
    
    func write(_ transaction: @escaping (Database) throws -> Void, callback: @escaping (Result<Void, Error>) -> Void) {
        asyncWrite(transaction) { callback($1) }
    }
    
}

private extension Swift.Result where Success == Database {
    
    func access() throws -> Database {
        switch self {
        case .success(let database): return database
        case .failure(let error):    throw error
        }
    }
    
}
