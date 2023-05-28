//
//  CGRect+Center.swift
//  Serifian
//
//  Created by Riccardo Persello on 28/05/23.
//

import Foundation

extension CGRect {
    init(center: CGPoint, size: CGSize) {
        let origin = CGPoint(x: center.x - size.width / 2, y: center.y - size.height / 2)
        self.init(origin: origin, size: size)
    }

    var center: CGPoint {
        return CGPoint(x: self.midX, y: self.midY)
    }
}
