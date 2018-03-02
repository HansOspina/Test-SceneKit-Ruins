//
//  Player.swift
//  Ruins
//
//  Created by Hans Ospina on 2/18/18.
//  Copyright © 2018 SBXCLOUD Inc. All rights reserved.
//

import Foundation

import SceneKit

enum PlayerAnimationType {
    case walk,attack1,dead
}

class Player: SCNNode {
    
    //nodes
    private var daeHolderNode = SCNNode()
    private var characterNode:SCNNode!
    
    // animations
    private var walkAnimation = CAAnimation()
    private var attack1Aniamtion = CAAnimation()
    private var deadAnimation = CAAnimation()
    
    
    // movement
    private var previousUpdateTime = TimeInterval(0.0)
    private var isWalking:Bool = false {
    
        didSet {
            if oldValue != isWalking {
                if isWalking {
                    characterNode.addAnimation(walkAnimation, forKey: "walk")
                }else{
                    characterNode.removeAnimation(forKey: "walk", blendOutDuration: 0.2)
                }
            }
        }
    }
    
    private var directionAngle:Float = 0.0 {
        didSet {
            if directionAngle != oldValue {
                runAction(SCNAction.rotateTo(x: 0.0, y: CGFloat(directionAngle), z: 0.0, duration: 0.1, usesShortestUnitArc: true))
            }
        }
    }
    //MARK:- initialization
    
    override init() {
        super.init()
        setupModel()
        loadAnimations()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    //MARK:- model
    private func setupModel(){
        // load dae node
        let playerULR = Bundle.main.url(forResource: "art.scnassets/Scenes/Hero/idle", withExtension: "dae")
        let playerScene = try! SCNScene(url: playerULR!, options: nil)
        
        for child in playerScene.rootNode.childNodes {
            daeHolderNode.addChildNode(child)
        }
        
        addChildNode(daeHolderNode)
        
        characterNode = daeHolderNode.childNode(withName: "Bip01", recursively: true)!
        
    }
    
    
    //MARK:- animations
    private func loadAnimations(){
        loadAnimation(animationType: .walk, inSceneNamed: "art.scnassets/Scenes/Hero/walk", withIdentifier: "WalkID")
        loadAnimation(animationType: .dead, inSceneNamed: "art.scnassets/Scenes/Hero/die", withIdentifier: "DeathID")
        loadAnimation(animationType: .attack1, inSceneNamed: "art.scnassets/Scenes/Hero/attack", withIdentifier: "attackID")
    }
    
    private func loadAnimation(animationType: PlayerAnimationType, inSceneNamed scene:String, withIdentifier identifier:String) {
        let sceneURL = Bundle.main.url(forResource: scene, withExtension: "dae")!
        let sceneSource = SCNSceneSource(url: sceneURL, options: nil)!
        let animationObject: CAAnimation = sceneSource.entryWithIdentifier(identifier, withClass: CAAnimation.self)!
        animationObject.delegate = self
        animationObject.fadeInDuration = 0.2
        animationObject.fadeOutDuration = 0.2
        animationObject.usesSceneTimeBase = false
        animationObject.repeatCount = 0
        
        switch animationType {
        case .walk:
            animationObject.repeatCount = Float.greatestFiniteMagnitude
            walkAnimation = animationObject
        case .dead:
            animationObject.isRemovedOnCompletion = false
            deadAnimation = animationObject
        case .attack1:
            animationObject.setValue("attack1", forKey: "animationId")
            attack1Aniamtion = animationObject
        }
        
    }
    
    func  walkInDirection(_ direction: float3, time: TimeInterval, scene: SCNScene){
    
        if previousUpdateTime == 0.0 {
            previousUpdateTime = time
        }
        
        let deltaTime = Float(min(time-previousUpdateTime,1.0/60.0))
        let characterSpeed = deltaTime * 1.3
        
        if direction.x != 0.0 && direction.z != 0.0 {
            // move character
            let pos = float3(position)
            position = SCNVector3(pos+direction * characterSpeed)
            
            // update angle
            directionAngle = SCNFloat(atan2f(direction.x, direction.z))
            
            isWalking = true
        }else{
            isWalking = false
        }
    }
}

//MARK:-extensions

extension Player:CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        // TODO: later
    }
}
