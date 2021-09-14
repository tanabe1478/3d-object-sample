//
//  ARPlaneAnchor + Extension.swift
//  3d-object-sample
//
//  Created by tanabe.nobuyuki on 2021/09/13.
//


import UIKit
import SceneKit
import ARKit
import SceneKit.ModelIO

extension ARPlaneAnchor {
    
    @discardableResult
    func addPlaneNode(on node: SCNNode, geometry: SCNGeometry, contents: Any) -> SCNNode {
        guard let material = geometry.materials.first else { fatalError() }
        
        if let program = contents as? SCNProgram {
            material.program = program
        } else {
            material.diffuse.contents = contents
        }
        
        let planeNode = SCNNode(geometry: geometry)
        
        DispatchQueue.main.async(execute: {
            node.addChildNode(planeNode)
        })
        
        return planeNode
    }

    func addPlaneNode(on node: SCNNode, contents: Any) {
        let geometry = SCNPlane(width: CGFloat(extent.x), height: CGFloat(extent.z))
        let planeNode = addPlaneNode(on: node, geometry: geometry, contents: contents)
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2.0, 1, 0, 0)
    }
    
    func findPlaneNode(on node: SCNNode) -> SCNNode? {
        for childNode in node.childNodes {
            if childNode.geometry as? SCNPlane != nil {
                return childNode
            }
        }
        return nil
    }

    func findShapedPlaneNode(on node: SCNNode) -> SCNNode? {
        for childNode in node.childNodes {
            if childNode.geometry as? ARSCNPlaneGeometry != nil {
                return childNode
            }
        }
        return nil
    }

    @available(iOS 11.3, *)
    func findPlaneGeometryNode(on node: SCNNode) -> SCNNode? {
        for childNode in node.childNodes {
            if childNode.geometry as? ARSCNPlaneGeometry != nil {
                return childNode
            }
        }
        return nil
    }

    @available(iOS 11.3, *)
    func updatePlaneGeometryNode(on node: SCNNode) {
        DispatchQueue.main.async(execute: {
            guard let planeGeometry = self.findPlaneGeometryNode(on: node)?.geometry as? ARSCNPlaneGeometry else { return }
            planeGeometry.update(from: self.geometry)
        })
    }

    func updatePlaneNode(on node: SCNNode) {
        DispatchQueue.main.async(execute: {
            guard let plane = self.findPlaneNode(on: node)?.geometry as? SCNPlane else { return }
            guard !PlaneSizeEqualToExtent(plane: plane, extent: self.extent) else { return }
            
            plane.width = CGFloat(self.extent.x)
            plane.height = CGFloat(self.extent.z)
        })
    }
}

fileprivate func PlaneSizeEqualToExtent(plane: SCNPlane, extent: vector_float3) -> Bool {
    if plane.width != CGFloat(extent.x) || plane.height != CGFloat(extent.z) {
        return false
    } else {
        return true
    }
}



extension UIColor {
    class var arBlue: UIColor {
        get {
            return UIColor(red: 0.141, green: 0.540, blue: 0.816, alpha: 1)
        }
    }
}

extension ARSession {
    func run() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.isLightEstimationEnabled = true
        run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
}

extension SCNNode {
    
    class func sphereNode(color: UIColor) -> SCNNode {
        let geometry = SCNSphere(radius: 0.01)
        geometry.materials.first?.diffuse.contents = color
        return SCNNode(geometry: geometry)
    }
    
    class func textNode(text: String) -> SCNNode {
        let geometry = SCNText(string: text, extrusionDepth: 0.01)
        geometry.alignmentMode = convertFromCATextLayerAlignmentMode(CATextLayerAlignmentMode.center)
        if let material = geometry.firstMaterial {
            material.diffuse.contents = UIColor.white
            material.isDoubleSided = true
        }
        let textNode = SCNNode(geometry: geometry)

        geometry.font = UIFont.systemFont(ofSize: 1)
        textNode.scale = SCNVector3Make(0.02, 0.02, 0.02)

        // Translate so that the text node can be seen
        let (min, max) = geometry.boundingBox
        textNode.pivot = SCNMatrix4MakeTranslation((max.x - min.x)/2, min.y - 0.5, 0)
        
        // Always look at the camera
        let node = SCNNode()
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = SCNBillboardAxis.Y
        node.constraints = [billboardConstraint]

        node.addChildNode(textNode)
        
        return node
    }
    
    class func lineNode(length: CGFloat, color: UIColor) -> SCNNode {
        let geometry = SCNCapsule(capRadius: 0.004, height: length)
        geometry.materials.first?.diffuse.contents = color
        let line = SCNNode(geometry: geometry)
        
        let node = SCNNode()
        node.eulerAngles = SCNVector3Make(Float.pi/2, 0, 0)
        node.addChildNode(line)
        
        return node
    }

    func loadScn(name: String, inDirectory directory: String) {
        guard let scene = SCNScene(named: "\(name).scn", inDirectory: directory) else { fatalError() }
        for child in scene.rootNode.childNodes {
            child.geometry?.firstMaterial?.lightingModel = .physicallyBased
            addChildNode(child)
        }
    }
    
    func loadUsdz(name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "usdz") else { fatalError() }
        let scene = try! SCNScene(url: url, options: [.checkConsistency: true])
        for child in scene.rootNode.childNodes {
            child.geometry?.firstMaterial?.lightingModel = .physicallyBased
            addChildNode(child)
        }
    }
}

extension SCNView {
    
    private func enableEnvironmentMapWithIntensity(_ intensity: CGFloat) {
        if scene?.lightingEnvironment.contents == nil {
            if let environmentMap = UIImage(named: "models.scnassets/sharedImages/environment_blur.exr") {
                scene?.lightingEnvironment.contents = environmentMap
            }
        }
        scene?.lightingEnvironment.intensity = intensity
    }

    func updateLightingEnvironment(for frame: ARFrame) {
        // If light estimation is enabled, update the intensity of the model's lights and the environment map
        let intensity: CGFloat
        if let lightEstimate = frame.lightEstimate {
            intensity = lightEstimate.ambientIntensity / 400
        } else {
            intensity = 2
        }
        DispatchQueue.main.async(execute: {
            self.enableEnvironmentMapWithIntensity(intensity)
        })
    }
}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromCATextLayerAlignmentMode(_ input: CATextLayerAlignmentMode) -> String {
    return input.rawValue
}



class VirtualObjectNode: SCNNode {

    enum VirtualObjectType {
        case duck
        case wheelbarrow
        case teapot
    }
    
    init(type: VirtualObjectType = .duck) {
        super.init()
        
        var scale = 1.0
        switch type {
        case .duck:
            loadScn(name: "duck", inDirectory: "models.scnassets/duck")
        case .wheelbarrow:
            loadUsdz(name: "wheelbarrow")
            scale = 0.005
        case .teapot:
            loadUsdz(name: "teapot")
            scale = 0.005
        }
        self.scale = SCNVector3(scale, scale, scale)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func react() {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.3
        SCNTransaction.completionBlock = {
            SCNTransaction.animationDuration = 0.15
            self.opacity = 1.0
        }
        self.opacity = 0.5
        SCNTransaction.commit()
    }
}
