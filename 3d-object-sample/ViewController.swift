import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet weak var segment: UISegmentedControl!
    @IBOutlet var sceneView: ARSCNView!
    var omniLight: SCNLight!
    var selected3DObject: Selected3DObject = .banana
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.showsStatistics = true
        sceneView.scene = SCNScene()
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        addTapGesture()
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.environmentTexturing = .automatic
        sceneView.session.run(configuration)
    }
    
    private func addTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
        sceneView.addGestureRecognizer(tapGesture)
    }
    
    @objc func tapped(_ target: UITapGestureRecognizer) {
        let view = target.view as! ARSCNView
        let touchPosition = target.location(in: view)
        // iOS14以降はraycastを使用するべきらしい。平面アンカーのフレームを考慮した位置を返してほしいのでexistingPlaneUsingExtent
        let hitTestResult = sceneView.hitTest(touchPosition, types: .existingPlaneUsingExtent)
        
        if !hitTestResult.isEmpty {
            guard let first = hitTestResult.first else { return }
            set3DObject(to: first)
        }
    }
    
    func set3DObject(to result: ARHitTestResult) {
        let transform = result.worldTransform
        let thirdColumn = transform.columns.3
        
        let item = load3DObjectNode()
        item.position = SCNVector3(thirdColumn.x, thirdColumn.y, thirdColumn.z)
        sceneView.scene.rootNode.addChildNode(item)
    }
    @IBAction func tappedSegment(_ sender: Any) {
        selected3DObject = Selected3DObject(from: segment.selectedSegmentIndex)
        print(selected3DObject.nodeName)
    }
    
    func load3DObjectNode() -> SCNNode {
//        daeの場合はこっち
//        let url = Bundle.main.url(forResource: "models.scnassets/banana", withExtension: "dae")!
//        let sceneSource = SCNSceneSource(url: url, options: nil)!
//        let virtualObjectNode
//            = sceneSource.entryWithIdentifier("banana", withClass: SCNNode.self)!
//        return virtualObjectNode
        
        let scene = SCNScene(named: selected3DObject.assetName)

        let node = scene?.rootNode.childNode(withName: selected3DObject.nodeName, recursively: true)
        return node!
    }
    
}

enum Selected3DObject {
    case banana
    case harinezumi
    case ship
    case edamame
    
    init(from intValue: Int) {
        switch intValue {
        case 0: self = .banana
        case 1: self = .harinezumi
        case 2: self = .edamame
        case 3: self = .ship
        default: fatalError()
        }
    }
    
    var assetName: String {
        switch self {
        case .banana: return "models.scnassets/banana.scn"
        case .edamame: return "models.scnassets/edamame.scn"
        case .harinezumi: return "models.scnassets/harinezumi.scn"
        case .ship: return "models.scnassets/ship.scn"
        }
    }
    
    var nodeName: String {
        switch self {
        case .banana: return "banana"
        case .edamame: return "edamame"
        case .harinezumi: return "harinezumi"
        case .ship: return "ship"
        }
    }
}
