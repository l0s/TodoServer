//
//  Todo.swift
//  Application
//
//  Created by Macasaet, Carlos on 20/10/18.
//

import Foundation

public struct ToDo: Codable, Equatable {

    // FIXME it's weird having all the fields be optional

    public var id: Int? // this is not immediately available
    public var user: String?
    public var title: String?
    public var order: Int?
    public var completed: Bool?
    public var url: String?

    public static func ==(lhs: ToDo, rhs: ToDo) -> Bool {
        return lhs.id == rhs.id
    }

}
