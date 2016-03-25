//
//  Game.swift
//  Nitrogen
//
//  Created by David Chavez on 20/03/16.
//  Copyright © 2016 Mystical. All rights reserved.
//

import Foundation
import RealmSwift

class Game: Object {
    dynamic var title: String = ""
    dynamic var serial: String = ""
    dynamic var path: String = ""
    dynamic var processed: Bool = false
    dynamic var artworkURL: String? = nil
}