//
//  GrdbStorage.swift
//  StorageSolutions
//
//  Created by sugarbaron on 28.09.2022.
//

import Foundation
import Combine
import GRDB
import CoreToolkit

// MARK: constructor
public final class GrdbStorage {
    
    private let access: DatabaseQueue
    private let scheduler: DispatchQueue
    
    public init?(_ sqliteFile: URL, _ versions: [GrdbSchemaVersion], _ config: Configuration) {
        guard let access: DatabaseQueue = start(database: sqliteFile, versions, config)
        else {
            return nil
        }
        self.access = access
        self.scheduler = DispatchQueue(label: "\(config.label ?? "Grdb")Scheduler", qos: .default)
    }
    
}

private func start(
    database sqliteFile: URL,
    _ versions: [GrdbSchemaVersion],
    _ config: Configuration
)
-> DatabaseQueue? {
    let sqlitePath: String = sqliteFile.absoluteString
    guard let access: DatabaseQueue = try? .init(path: sqlitePath, configuration: config),
          load(schema: versions, access)
    else { log(error: "[GrdbStorage] unable to construct:[\(sqlitePath)]"); return nil }
    return access
}

private func load(schema versions: [GrdbSchemaVersion], _ access: DatabaseQueue) -> Bool {
    var editor: DatabaseMigrator = .init()
    editor.eraseDatabaseOnSchemaChange = false
    versions.forEach { editor.registerMigration($0.id, migrate: $0.upgrade) }
    do    { try editor.migrate(access); return true }
    catch { log(error: "[GrdbStorage] load schema versions error: \(error)"); return false }
}

// MARK: interface
public extension GrdbStorage {
    
    func keepInformed<T>(about updates: @escaping (Database) throws -> T) -> GrdbStorage.Subscription<T> {
        ValueObservation.tracking(updates).values(in: access, scheduling: .async(onQueue: scheduler))
    }
    
    func keepInformed<T>(about updates: @escaping (Database) throws -> T) -> Downstream<T> {
        let logged: (Database) throws -> T = {
            if Thread.isMain { log(error: "[GrdbStorage] reading on main is denied") }
            return try updates($0)
        }
        return Publishers.reborn { [weak self] in self?.track(logged) }
                   catch: { log(error: "[GrdbStorage] reactive subscription error: \($0)") }
                   .abstract()
    }
    
    private func track<T>(_ updates: @escaping (Database) throws -> T) -> AnyPublisher<T, Error> {
        ValueObservation.tracking(updates)
            .publisher(in: access, scheduling: .async(onQueue: scheduler))
            .anyPublisher
    }
    
    func read<T>(
        _ transaction: @Sendable @escaping (Database) throws -> T,
        catch: (Error) -> Void = { log(error: "[GrdbStorage] read() async -> T? error: \($0)") }
    )
    async -> T? {
        do    { return try await execute(read: transaction) }
        catch { `catch`(error); return nil }
    }
    
    func read<T>(
        _ transaction: @Sendable @escaping (Database) throws -> T,
        catch: (Error) -> Void = { log(error: "[GrdbStorage] read() async -> T error: \($0)") }
    )
    async -> T where T : Nullable {
        do    { return try await execute(read: transaction) }
        catch { `catch`(error); return nil }
    }
    
    func read<T>(
        _ transaction: @Sendable @escaping (Database) throws -> [T],
        catch: (Error) -> Void = { log(error: "[GrdbStorage] read() async -> [T] error: \($0)") }
    )
    async -> [T] {
        do    { return try await execute(read: transaction) }
        catch { `catch`(error); return [ ] }
    }
    
    func write(
        _ transaction: @Sendable @escaping (Database) throws -> Void,
        catch: (Error) -> Void = { log(error: "[GrdbStorage] write() async error: \($0)") }
    )
    async {
        do    { try await execute(write: transaction) }
        catch { `catch`(error) }
    }
    
    func write(
        _ transaction:  @escaping (Database) throws -> Void,
        callback:       @escaping () -> Void = { },
        catch:          @escaping (Error) -> Void = { log(error: "[GrdbStorage] write() error: \($0)") }
    ) {
        access.write(transaction) {
            switch $0 {
            case .success: callback()
            case .failure(let error): `catch`(error)
            }
        }
    }
    
    typealias Subscription = AsyncValueObservation
    
}

// MARK: tools
private extension GrdbStorage {
    
    func execute<T>(read transaction: @Sendable @escaping (Database) throws -> T) async throws -> T {
        try await concurrent { [weak self] coroutine in
            guard let self: GrdbStorage
            else {
                coroutine.resume(throwing: Exception("[GrdbStorage][read] deallocated"))
                return
            }
            access.read(transaction) {
                switch $0 {
                case .success(let read):  coroutine.resume(returning: read)
                case .failure(let error): coroutine.resume(throwing: error)
                }
            }
        }
    }
    
    func execute(write transaction: @Sendable @escaping (Database) throws -> Void) async throws {
        try await concurrent { [weak self] coroutine in
            guard let self: GrdbStorage
            else {
                let exception: Result<Void, Exception> = .failure(Exception("[GrdbStorage][write] deallocated"))
                coroutine.resume(with: exception)
                return
            }
            access.write(transaction) {
                switch $0 {
                case .success:            coroutine.resume()
                case .failure(let error): coroutine.resume(throwing: error)
                }
            }
        }
    }
    
}
