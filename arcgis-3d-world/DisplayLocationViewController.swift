//
//  DisplayLocationViewController.swift
//  arcgis-helloworld
//
//  Created by Lucas Mckenna on 8/30/18.
//  Copyright © 2018 Lucas Mckenna. All rights reserved.
//

import UIKit
import ArcGIS
import MotionDnaSDK

class DisplayLocationViewController: UIViewController {
    
    @IBOutlet private weak var mapView:AGSSceneView!
    private let location_controller = MotionDnaLocationDisplay()
    private var map:AGSScene!
    private var sceneGraphicsOverlay : AGSGraphicsOverlay!
    private var sphereGraphic : AGSGraphic!
    private var graphicsOverlay = AGSGraphicsOverlay()
    private var location_symbol : AGSSimpleMarkerSceneSymbol!
    private var heading_symbol : AGSSimpleMarkerSceneSymbol!
    private var sphere_symbol : AGSModelSceneSymbol!
    private var portal: AGSPortal!
    private var portalItem: AGSPortalItem!
    private let motionDnaSDK = MotionDnaLocationDisplay()
    var z_offset=CLLocationDistance(0)
    
    private func addGraphics() {
        
        // Load mesh into system.
        let point = AGSPoint(x:0.0, y:0.0, z: 0.0, spatialReference: AGSSpatialReference.wgs84())
        sphere_symbol = AGSModelSceneSymbol(name: "sphere", extension: "dae", scale: 1)
        sphere_symbol.load { (error) in
            
            // Mesh loaded callback.
            self.sphere_symbol.anchorPosition = AGSSceneSymbolAnchorPosition.center
            self.sphereGraphic = AGSGraphic(geometry: point, symbol: self.sphere_symbol, attributes: nil)
            self.graphicsOverlay.graphics.add(self.sphereGraphic)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Instantiate the SDK.
        motionDnaSDK.receiver=self
        motionDnaSDK.start()
        
        // Start Esri portal to render Esri 3D map of campus.
        portal = AGSPortal.arcGISOnline(withLoginRequired: false)
       
        // Esri 3D portal item.
        let portalItem = AGSPortalItem.init(portal: portal, itemID: "b1f8fb3b2fd14cc2a78728de108776b0")
        
        // Create scene from portal item
        let scene = AGSScene(item: portalItem)
        
        // Assign Scene to 3D canvas.
        self.mapView.scene = scene
        
        // I need some custom attributes to apply attitude to mesh.
        let renderer = AGSSimpleRenderer()
        
        // Yaw pitch roll attributes for real time rotations on mesh.
        renderer.sceneProperties?.headingExpression = "[HEADING]"
        renderer.sceneProperties?.pitchExpression = "[PITCH]"
        renderer.sceneProperties?.rollExpression = "[ROLL]"
        
        // Set renderer on the overlay
        self.graphicsOverlay.renderer = renderer

        self.graphicsOverlay.sceneProperties?.surfacePlacement = .absolute
        self.mapView.graphicsOverlays.add(graphicsOverlay)

        self.addGraphics()
        
    }
    
    let sdk=MotionDnaSDK()
    
    func authFailure(){
        // Authentication failure.
        let alert = UIAlertController(title: "Authentication failure", message: "Please enter your developer key in the MotionDnaController.swift runMotionDna method. Get your key here: https://navisens.com/ ", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            switch action.style{
            case .default:
                print("default")
                
            case .cancel:
                print("cancel")
                
            case .destructive:
                print("destructive")
            }}))
        self.present(alert, animated: true, completion: nil)
    }
    
    func receive(_ motionDna: MotionDna!) {
        
        // Get initial altitude value and use that as ground data.
        if (z_offset == 0)
        {
            z_offset=motionDna.getLocation().absoluteAltitude
        }
        
        // Substract ground data to current baromteric measurement
        var _z=motionDna.getLocation().absoluteAltitude-z_offset
        
        // If below 0.9m set the altitude to 0.9m.
        if (_z < 1.8/2)
        {
            _z = 1.8/2;
        }
        
        // Map lon/lat/altitude to AGSPoint
        let pt = AGSPoint(x: motionDna.getLocation().globalLocation.longitude,
                          y: motionDna.getLocation().globalLocation.latitude,
                          z: _z, spatialReference: AGSSpatialReference.wgs84())
        DispatchQueue.main.async {
            
            // Convert Navisens MotionDna rotation frame to ARCGis 3D rendering frame.
            // Convert Naviens MotionDna Attitude from radians to degrees.
            self.sphereGraphic.attributes["HEADING"]=(motionDna.getAttitude().yaw * 57.2958) * -1
            self.sphereGraphic.attributes["ROLL"]=(motionDna.getAttitude().roll * 57.2958)
            self.sphereGraphic.attributes["PITCH"]=(motionDna.getAttitude().pitch * 57.2958) * -1
            
            // Assign mesh geometry to point.
            self.sphereGraphic.geometry=pt
        }
    }
}


// MotionDna class, since we require to phone's attitude I had to receive the location data from
// our traditional receiveMotionDna method.
class MotionDnaLocationDisplay: MotionDnaSDK
{
    var receiver : DisplayLocationViewController?
    
    func start(){
        // Enter the key you got from www.navisens.com
        self.runMotionDna("YOUR_DEVELOPER_KEY", receiver: self)
        self.setExternalPositioningState(HIGH_ACCURACY)
        self.setCallbackUpdateRateInMs(0)
        // Entrance to Esri.
        self.setLocationLatitude(34.055920, longitude: -117.195647, andHeadingInDegrees: 0)
    }
    
    override func receive(_ motionDna: MotionDna!) {
        // Receive location data.
        receiver?.receive(motionDna)
    }
    
    override func reportError(_ error: ErrorCode, withMessage message: String!) {
        if (error==AUTHENTICATION_FAILED)
        {
            // If this gets called nothing will run and will show popup, ensure you have internet to authenticate the SDK.
            receiver?.authFailure()
        }
    }
}
