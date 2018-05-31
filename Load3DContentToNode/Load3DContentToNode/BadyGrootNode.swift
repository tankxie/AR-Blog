//
//  IronManNode.swift
//  Load3DContentToNode
//
//  Created by tank on 2018/5/31.
//  Copyright © 2018 webank. All rights reserved.
//

import UIKit
import SceneKit

class BadyGrootNode: SCNNode {
    override init(){
        super.init()
        // 加载dae文件
        guard  let url = Bundle.main.url(forResource: "baby_groot", withExtension: "dae") else {
            fatalError("baby_groot.dae not exit.")
        }
        // 加载scn文件
//        guard  let url = Bundle.main.url(forResource: "baby_groot", withExtension: "scn") else {
//            fatalError("baby_groot.scn not exit.")
//        }
        guard let customNode = SCNReferenceNode(url: url) else {
            fatalError("load baby_groot error.")
        }
        customNode.load()
        self.addChildNode(customNode)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
