
This is an example of Navisens' SDK integration with ArcGIS' 3D Visuals SDK.

Then retrieve a Navisens SDK key [here](https://navisens.com/).  
And add it to the `runMotionDna` method in the `DisplayLocationViewController.swift` file.

When you are done with all your key retrievals, run:
```
pod install // Will install latest MotionDna SDK and ArcGIS SDK version 100.3
open arcgis-3d-world.xcworkspace // Will launch xcode
```

After completing the setup, you'll be able to see the Navisens location in 3D starting from Esri's HQ
in Redlands.

Have fun!
<video src="esri_3d.mp4" width="320" height="200" controls preload></video>
