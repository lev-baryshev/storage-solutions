//
//  GrdbStorageTests.swift
//  StorageSolutions
//
//  Created by sugarbaron on 26.02.2026.
//

@testable
import StorageSolutions
import XCTest
import GRDB
import CoreToolkit

// MARK: - tests
final class GrdbStorageTests : XCTestCase {

    private var sqliteFile: URL!
    private var database: GrdbStorage!

    func testWriteRead() async throws {
        try await test {
            let record: RecordExample = .init(id: 1, name: "Test Name")
            
            await database.write {
                try $0.insert(record)
            }
            let loaded: RecordExample? = await database.read {
                try $0.select(RecordExample.where(Column(Columns.id) == record.id))
            }
            
            XCTAssertNotNil(loaded)
            XCTAssertEqual(loaded?.id,   record.id)
            XCTAssertEqual(loaded?.name, record.name)
        }
    }

    func testReadList() async throws {
        try await test {
            let records: [RecordExample] = [
                .init(id: 1, name: "One"),
                .init(id: 2, name: "Two")
            ]
            
            await database.write { database in
                try records.forEach { try database.insert($0) }
            }
            let loaded: [RecordExample] = await database.read {
                try $0.select(all: RecordExample.self)
            }
            
            XCTAssertEqual(loaded.count, 2)
            XCTAssertTrue(loaded.contains { $0.id == 1 && $0.name == "One" })
            XCTAssertTrue(loaded.contains { $0.id == 2 && $0.name == "Two" })
        }
    }

    func testReadMissing() async throws {
        try await test {
            let loaded: RecordExample? = await database.read {
                try $0.select(RecordExample.where(Column(Columns.id) == 999))
            }
            XCTAssertNil(loaded)
        }
    }

    func testConstraintViolation() async throws {
        try await test {
            let record: RecordExample = .init(id: 1, name: "Test")
            await database.write {
                try $0.insert(record)
            }
            
            var errorThrown: Bool = false
            await database.write {
                try $0.insert(record)
            } catch: { _ in
                errorThrown = true
            }
            
            XCTAssertTrue(errorThrown)
        }
    }
    
}

// MARK: tools
private extension GrdbStorageTests {
    
    func test(_ test: () async throws -> Void) async throws {
        setup()
        try await test()
        await reset()
    }
    
    func setup() {
        let sqliteFile: URL = .init(fileURLWithPath: ":memory:")
        let migration: [StorageExample.V01] = [.init()]
        let config: Configuration = .config("StorageExample")
        guard let database: GrdbStorage = .init(sqliteFile, migration, config)
        else {
            XCTFail("unable to construct database")
            return
        }
        self.sqliteFile = sqliteFile
        self.database = database
    }
    
    func reset() async {
        await database.write { try $0.delete(all: RecordExample.self) }
        self.database = nil
        self.sqliteFile = nil
    }
    
}

// MARK: record example
private struct RecordExample {
    
    let id: Int
    let name: String
    
    init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
    
}

extension RecordExample : GrdbRecord {
    
    static let tableName: String = "records"
    
    func save(into row: inout PersistenceContainer) throws {
        row[Columns.id] = id
        row[Columns.name] = name
    }
    
    static func load(from row: Row) throws -> RecordExample {
        RecordExample.init(
            id:     row[Columns.id],
            name:   row[Columns.name]
        )
    }
    
}

// MARK: storage schema
private final class StorageExample { }

extension StorageExample {
    
    final class V01 : GrdbSchemaVersion {
        
        let id: String = "v01"
        
        let upgrade: (Database) throws -> Void = { database in
            try database.create(table: RecordExample.tableName) { table in
                table.column(Columns.id,    .integer).notNull().primaryKey()
                table.column(Columns.name,  .text).notNull()
            }
        }
        
    }
    
}

private final class Columns {
    static let id: String = "id"
    static let name: String = "name"
}
