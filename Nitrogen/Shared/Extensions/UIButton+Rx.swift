//
//  UIButton+Rx.swift
//  Nitrogen
//
//  Created by David Chavez on 25/03/16.
//  Copyright © 2016 Mystical. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

extension UIButton {

    /**
     Reactive wrapper for `[.TouchUpInside, .TouchDragExit, .TouchUpOutside]` control event.
     */
    public var rx_untap: ControlEvent<Void> {
        return rx_controlEvent([.TouchUpInside, .TouchDragExit, .TouchUpOutside])
    }

    /**
     Reactive wrapper for `[.TouchDown]` control event.
     */
    public var rx_touchdown: ControlEvent<Void> {
        return rx_controlEvent([.TouchDown])
    }
}
