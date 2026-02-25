//
//  Storages.swift
//  StorageSolutions
//
//  Created by sugarbaron on 22.11.2022.
//

import CoreToolkit

public final class Storages {
    
    public static func decompose<I, L, Id>(
        _ allIncoming: [I],
        for allLocal: [Id : L],
        id idField: KeyPath<I, Id>
    ) -> Incoming<I, Id> {
        var incomingIds: [Id] = [ ]
        var new: [I] = [ ]
        var updated: [I] = [ ]
        allIncoming.forEach { incoming in
            let id: Id = incoming[keyPath: idField]
            incomingIds += id
            if allLocal[id] == nil {
                new += incoming
            } else {
                updated += incoming
            }
        }
        return Incoming(new, updated, incomingIds)
    }
    
}

public extension Storages {
    
    final class Incoming<I, Id> {
        
        public let new: [I]
        public let updated: [I]
        public let ids: [Id]
        
        init(_ new: [I], _ updated: [I], _ ids: [Id]) {
            self.new = new
            self.updated = updated
            self.ids = ids
        }
        
    }
    
}

