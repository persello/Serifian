//
//  DraggableDividerView.swift
//  Serifian
//
//  Created by Riccardo Persello on 28/05/23.
//

import UIKit

class DraggableDividerView: UIView {

    class DividerDraggerView: UIView {
        override init(frame: CGRect) {
            super.init(frame: frame)
            self.bounds = frame
            self.backgroundColor = .clear
            self.translatesAutoresizingMaskIntoConstraints = false
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            self.backgroundColor = .clear
            self.translatesAutoresizingMaskIntoConstraints = false
        }

        override func draw(_ rect: CGRect) {
            let rect = CGRect(center: rect.center, size: CGSize(width: 8, height: 48))
            let path = UIBezierPath(roundedRect: rect, cornerRadius: 4)
            UIColor.opaqueSeparator.setStroke()
            UIColor.systemGray6.setFill()
            path.lineWidth = 0.5
            path.fill()
            path.stroke()
        }
    }

    private unowned var dragger: DividerDraggerView!
    unowned var panRecognizer: UIPanGestureRecognizer!

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addDragger()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.addDragger()
    }

    override func draw(_ rect: CGRect) {
        let lineRect = CGRect(origin: rect.origin, size: CGSize(width: 0.5, height: rect.height))
        let path = UIBezierPath(rect: lineRect)
        UIColor.opaqueSeparator.setFill()
        path.fill()
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return dragger.frame.contains(point)
    }
    
    private func addDragger() {
        // Create the dragger view.
        let dragger = DividerDraggerView(frame: .init(origin: .zero, size: .init(width: 56, height: 56)))
        self.addSubview(dragger)

        // Add the constraints.
        let centerXConstraint = self.centerXAnchor.constraint(equalTo: dragger.centerXAnchor)
        let centerYConstraint = self.centerYAnchor.constraint(equalTo: dragger.centerYAnchor)
        let widthConstraint = dragger.widthAnchor.constraint(equalToConstant: 56)
        let heightConstraint = dragger.heightAnchor.constraint(equalToConstant: 56)

        self.translatesAutoresizingMaskIntoConstraints = false
        dragger.addConstraints([heightConstraint, widthConstraint])
        self.addConstraints([centerXConstraint, centerYConstraint])

        // Show the dragger.
        self.bringSubviewToFront(dragger)

        // Add pan gesture recognizer.
        let panGestureRecognizer = UIPanGestureRecognizer()
        panGestureRecognizer.minimumNumberOfTouches = 1
        self.addGestureRecognizer(panGestureRecognizer)

        // Save references.
        self.panRecognizer = panGestureRecognizer
        self.dragger = dragger
    }
}
