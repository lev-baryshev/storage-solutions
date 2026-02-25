//
//  GrdbRecord.swift
//  StorageSolutions
//
//  Created by sugarbaron on 02.10.2022.
//

import GRDB
import CoreToolkit

public protocol GrdbRecord : TableRecord, FetchableRecord, MutablePersistableRecord {

    static var tableName: String { get }

    func save(into row: inout PersistenceContainer) throws

    static func load(from row: Row) throws -> Self

}

public extension GrdbRecord {

    static var databaseTableName: String { tableName }

    init(row: Row) throws {
        do    { self = try Self.load(from: row) }
        catch { throw Exception("[GrdbRecord] unable to load:[\(String(describing: Self.self))]: \(error)") }
    }

    func encode(to container: inout PersistenceContainer) throws {
        do    { try save(into: &container) }
        catch { throw Exception("[GrdbRecord] unable to save:[\(String(describing: Self.self))]: \(error)") }
    }

}
