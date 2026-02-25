//
//  GrdbSchemaVersion.swift
//  StorageSolutions
//
//  Created by sugarbaron on 03.10.2022.
//

import GRDB

public protocol GrdbSchemaVersion {

    var id: String { get }
    /// upgrade to this version from previous
    var upgrade: (Database) throws -> Void { get }

}
