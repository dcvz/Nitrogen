//
//  Functions.swift
//  Nitrogen
//
//  Created by David Chavez on 20/03/16.
//  Copyright © 2016 Mystical. All rights reserved.
//

import Foundation

/**
 Encloses a try method and silently but customizably handles fails.
 _It logs any errors through EFLogError._
 - parameter f: This is the try method to attempt.
 - returns: The expected return type value if successful, nil if not.
 */
func enclose<T>(@noescape f: () throws -> T) -> T? {
    do {
        return try f()
    } catch {
        print("Error: \(error)")
        return nil
    }
}

func delay(delay:Double, closure:()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
}
