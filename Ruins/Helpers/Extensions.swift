//
//  Extensions.swift
//  Ruins
//
//  Created by Hans Ospina on 2/20/18.
//  Copyright © 2018 SBXCLOUD Inc. All rights reserved.
//

import Foundation
import SceneKit

extension float2 {
    init(_ v:CGPoint) {
        self.init(Float(v.x), Float(v.y))
    }
}

extension SCNPhysicsContact {
    
    func match(_ category: Int, block: (SCNNode,SCNNode) -> Void)  {
        
        if self.nodeA.physicsBody!.categoryBitMask == category {
            block(self.nodeA, self.nodeB)
        }
        
        if self.nodeB.physicsBody!.categoryBitMask == category {
            block(self.nodeB, self.nodeA)
        }
        
    }
}
