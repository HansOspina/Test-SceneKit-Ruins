//
//  GameViewController.swift
//  Ruins
//
//  Created by Hans Ospina on 2/18/18.
//  Copyright © 2018 MobileAWS, LLC d/b/a AllCode. All rights reserved.
//

import UIKit
import SceneKit

enum GameState {
    case loading, playing
}

let BitmaskPlayer = 1
let BitmaskPlayerWeapon = 2
let BitmaskWall = 64
let BitmaskGolem = 3


class GameViewController: UIViewController {
    
    // scene props
     var gameView:GameView { return view as! GameView }
    var mainScene: SCNScene!
    
    // general props
    var gameState:  GameState = .loading
    
    //nodes
    private var player: Player?
    private var cameraStick: SCNNode!
    private var cameraXHolder: SCNNode!
    private var cameraYHolder: SCNNode!
    private var lightStick:SCNNode!
    
    
    //movement
    private var controllerStoredDirection = float2(0.0)
    private var padTouch:UITouch?
    private var cameraTouch:UITouch?
    
    // collisions
    private var maxPenetrationDistance = CGFloat(0.0)
    private var replacementPositions = [SCNNode:SCNVector3]()
    
    
    // MARK:- lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScene()
        setupPlayer()
        setupCamera()
        setupLight()
        setupWallBitmaks()
        gameState = .playing
        view.isUserInteractionEnabled = true
    }
    
    
    
    
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    //MARK:- scene
    func setupScene() {
        //gameView.allowsCameraControl = true
        gameView.antialiasingMode = .multisampling4X
        
        gameView.delegate = self
        
        mainScene = SCNScene(named: "art.scnassets/Scenes/Stage1.scn")
        mainScene.physicsWorld.contactDelegate = self
        gameView.scene = mainScene
        gameView.isPlaying = true
        
    }
    
    //MARK:- walls
    
    //MARK:- camera
    
    //MARK:- player
    private func setupPlayer(){
        
        self.player = Player()
        
        guard let player = self.player else {
            return
        }
        
        player.scale = SCNVector3Make(0.0026, 0.0026, 0.0026)
        player.position = SCNVector3Make(0.0,0.0,0.0)
        player.rotation = SCNVector4Make(0,1,0, Float.pi)
        mainScene.rootNode.addChildNode(player)
    }
    
    //MARK:- touches + movement 
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        for touch in touches {
            if gameView.virtualDpadBounds().contains(touch.location(in: gameView)){
                if padTouch == nil {
                    padTouch = touch
                    controllerStoredDirection = float2(0.0)
                }
            } else if cameraTouch == nil {
                cameraTouch = touches.first
            }
            
            if padTouch != nil { break }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if let touch = padTouch {
            let displacement = float2(touch.location(in: gameView)) - float2(touch.previousLocation(in: gameView))
            let vMix = mix(controllerStoredDirection, displacement, t:0.1)
            let vClamp = clamp(vMix, min: -1.0, max: 1.0)
            controllerStoredDirection = vClamp
            print(controllerStoredDirection)
        } else if let touch = cameraTouch {
            let displacement = float2(touch.location(in: gameView)) - float2(touch.previousLocation(in: gameView))
            panCamera(displacement)
        }
        
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        padTouch = nil
        controllerStoredDirection = float2(0.0)
        cameraTouch = nil
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        padTouch = nil
        controllerStoredDirection = float2(0.0)
        cameraTouch = nil
    }
    
    //MAK:- game loop functions
    
    private func characterDirection() -> float3{
        
        var direction = float3(controllerStoredDirection.x, 0.0, controllerStoredDirection.y)
        
        if let pov = gameView.pointOfView {
            let p1 = pov.presentation.convertPosition(SCNVector3(direction), to: nil)
            let p0 = pov.presentation.convertPosition(SCNVector3Zero, to: nil)
            
            direction = float3(Float(p1.x-p0.x), 0.0, Float(p1.z-p0.z))
            
            if direction.x != 0.0 || direction.z != 0.0 {
                direction = normalize(direction)
            }
            
        }
        
        return direction
    }
    
    func updateFollowersPosition(){
        cameraStick.position = SCNVector3Make(player!.position.x,0.0,player!.position.z)
        lightStick.position = SCNVector3Make(player!.position.x,0.0,player!.position.z)
    }
    
    //MARK:- enemies
    
    //MARK:- camera
    private func setupCamera(){
        cameraStick = mainScene.rootNode.childNode(withName: "CameraStick", recursively: false)!
        cameraXHolder = mainScene.rootNode.childNode(withName: "xHolder", recursively: true)!
        cameraYHolder = mainScene.rootNode.childNode(withName: "yHolder", recursively: true)!
    }
    
    func setupLight(){
        lightStick = mainScene.rootNode.childNode(withName: "LightStick", recursively: false)!
    }
    
    private func panCamera(_ direction: float2){
        var directionToPan = direction
        directionToPan *= float2(1.0,-1.0)
        let panReducer = Float(0.005)
        let currX = cameraXHolder.rotation
        let xRotationValue = currX.w  - directionToPan.x * panReducer

        let currY = cameraYHolder.rotation
        
        var yRotationValue = currY.w  - directionToPan.y * panReducer
        
        if yRotationValue < -0.94 { yRotationValue = -0.94 }
        if yRotationValue > 0.66 { yRotationValue = 0.66 }
        
        cameraXHolder.rotation = SCNVector4Make(0, 1, 0, xRotationValue)
        cameraYHolder.rotation = SCNVector4Make(1, 0, 0, yRotationValue)
    }
    
    private func setupWallBitmaks(){
        var collisionNodes = [SCNNode]()
        
        mainScene.rootNode.enumerateChildNodes { (node, _) in
            
            switch node.name {
            case let .some(s) where s.range(of: "colision") != nil:
                collisionNodes.append(node)
            default:
                break
            }
            
        }
        
        for node in collisionNodes {
            node.physicsBody = SCNPhysicsBody.static()
            node.physicsBody!.categoryBitMask = BitmaskWall
            node.physicsBody!.physicsShape = SCNPhysicsShape(node: node, options:[.type: SCNPhysicsShape.ShapeType.concavePolyhedron as NSString])
        }
    }
    
}


//MARK:- extensions

//physics
extension GameViewController:SCNPhysicsContactDelegate{
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        
        
        
    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didUpdate contact: SCNPhysicsContact) {
        
    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didEnd contact: SCNPhysicsContact) {
        
    }
    
    
}

// game loop
extension GameViewController: SCNSceneRendererDelegate{
    
    func renderer(_ renderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: TimeInterval) {
        
    }
    
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        guard gameState == .playing  else {
            return
        }
        
        // reset positions
        replacementPositions.removeAll()
        maxPenetrationDistance = 0.0
        
        
        let scene = gameView.scene!
        let direction = characterDirection()
        player!.walkInDirection(direction, time: time, scene: scene)
        
        
        updateFollowersPosition()
        
    }
    
    
    
}


