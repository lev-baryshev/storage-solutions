//
//  GrdbContributions.swift
//  StorageSolutions
//
//  Created by sugarbaron on 26.11.2022.
//

import CoreToolkit

public extension String {
    
    var sqlite: String { "\(self).sqlite" }
    
}

public protocol SqlLiteral {
    
    var sqlLiteral: String { get }
    
}

extension String    : SqlLiteral { public var sqlLiteral: String { "'\(self.escaped)'" } }
extension Int       : SqlLiteral { public var sqlLiteral: String { "\(self)" } }
extension Double    : SqlLiteral { public var sqlLiteral: String { "\(self)" } }
extension Bool      : SqlLiteral { public var sqlLiteral: String { self ? "TRUE" : "FALSE" } }

extension Optional : SqlLiteral where Wrapped : SqlLiteral {
    
    public var sqlLiteral: String { unwrap(self) { $0.sqlLiteral } ?? "NULL" }
    
}

extension Array : SqlLiteral where Element : SqlLiteral {
    
    public var sqlLiteral: String { "(\(String(map { $0.sqlLiteral }.joined)))" }
    
}

private extension String {
    
    var escaped: String { replace("'", with: "''") }
    
}
