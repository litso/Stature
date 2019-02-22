//
//  Grid.swift
//  Stature
//
//  Created by Robert Manson on 2/21/19.
//

import Foundation
import SceneKit
import ARKit

class Grid: SCNNode {
    var anchor: ARPlaneAnchor
    var planeGeometry: SCNPlane!
    var textGeometry: SCNText!
    var isSelected = false {
        didSet {

        }
    }

    init(anchor: ARPlaneAnchor) {
        self.anchor = anchor
        super.init()
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(anchor: ARPlaneAnchor) {
        self.anchor = anchor
        planeGeometry.width = CGFloat(anchor.extent.x)
        planeGeometry.height = CGFloat(anchor.extent.z)
        position = SCNVector3Make(anchor.center.x, 0, anchor.center.z)

        guard let planeNode = self.childNodes.first else { return }
        planeNode.physicsBody = SCNPhysicsBody(type: .static,
                                               shape: SCNPhysicsShape(geometry: self.planeGeometry,
                                                                      options: nil))

        if let textGeometry = self.childNode(withName: "textNode", recursively: true)?.geometry as? SCNText {
            updateText(textGeometry: textGeometry, isSelected: isSelected)
        }
    }
}

private extension Grid {
    func setup() {
        planeGeometry = SCNPlane(width: CGFloat(self.anchor.extent.x), height: CGFloat(self.anchor.extent.z))

        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: "overlay_grid.png")

        planeGeometry.materials = [material]
        let planeNode = SCNNode(geometry: self.planeGeometry)
        planeNode.physicsBody = SCNPhysicsBody(type: .static,
                                               shape: SCNPhysicsShape(geometry: planeGeometry, options: nil))
        planeNode.physicsBody?.categoryBitMask = 2

        planeNode.position = SCNVector3Make(anchor.center.x, 0, anchor.center.z)
        planeNode.transform = SCNMatrix4MakeRotation(Float(-Double.pi / 2.0), 1.0, 0.0, 0.0)

        let textNodeMaterial = SCNMaterial()
        textNodeMaterial.diffuse.contents = UIColor.black

        // Set up text geometry
        textGeometry = SCNText(string: "Tap", extrusionDepth: 1)
        textGeometry.font = UIFont.systemFont(ofSize: 10)
        textGeometry.materials = [textNodeMaterial]

        let textNode = SCNNode(geometry: textGeometry)
        textNode.name = "textNode"
        textNode.position = SCNVector3Make(anchor.center.x, 0, anchor.center.z)
        textNode.rotation = SCNVector4(1.0, 0.0, 0.0, -Double.pi / 2)
        textNode.scale = SCNVector3Make(0.01, 0.01, 0.01)

        addChildNode(textNode)
        addChildNode(planeNode)
    }

    func updateText(textGeometry: SCNText, isSelected: Bool) {
        textGeometry.string = isSelected ? "✅" : "Tap"
    }
}
