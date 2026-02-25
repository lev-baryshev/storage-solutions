//
//  GrdbConfiguration.swift
//  StorageSolutions
//
//  Created by sugarbaron on 28.11.2025.
//

import Foundation
import GRDB

public extension Configuration {
    
    static func config(
        _ name: String,
        qos: DispatchQoS    = .default,
        readonly: Bool      = false,
        foreignKeys: Bool   = true,
        readerThreads: Int  = 5 // (for DatabasePool case only)
    )
    -> Configuration {
        var config: Configuration = .init()
        config.label = "\(name)Access"
        config.targetQueue = DispatchQueue(label: "\(name)Queue", qos: qos)
        config.readonly = readonly
        config.foreignKeysEnabled = foreignKeys
        config.maximumReaderCount = readerThreads
        return config
    }
    
}
