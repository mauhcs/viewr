//
//  MLExtension.swift
//  ViewCan
//
//  Created by Mauricio Hernandes on 2019/12/15.
//  Copyright © 2019 Mauricio Hernandes. All rights reserved.
//

import UIKit
//import PromiseKit
import Firebase
import FirebaseMLVisionObjectDetection

// MARK - Custom Model Extension

class VisionModel {
    
    let remoteModel: CustomRemoteModel
    var ioOptions: ModelInputOutputOptions
    var interpreter : ModelInterpreter
    
    let labels = ["cat", "dog", "vendMachine"]
    
    init(){
    
        remoteModel = CustomRemoteModel(
          name: "cats_2019121518288"  // The name you assigned in the Firebase console.
        )
        
        let downloadConditions = ModelDownloadConditions(
          allowsCellularAccess: true,
          allowsBackgroundDownloading: true
        )

        let downloadProgress = ModelManager.modelManager().download(
          remoteModel,
          conditions: downloadConditions
        )
        
        if ModelManager.modelManager().isModelDownloaded(remoteModel) {
            print("Model is DOWNLOADED!!!!!!!!!!!")
          //interpreter = ModelInterpreter.modelInterpreter(remoteModel: remoteModel)
        } else {
          //interpreter = ModelInterpreter.modelInterpreter(remoteModel: remoteModel)
        }
        
        ioOptions = ModelInputOutputOptions()
        do {
            try ioOptions.setInputFormat(index: 0, type: .float32, dimensions: [1, 150, 150, 3])
            try ioOptions.setOutputFormat(index: 0, type: .float32, dimensions: [1, 3])
        } catch let error as NSError {
            print("Failed to set input or output format with error: \(error.localizedDescription)")
        }
    
        
        interpreter = ModelInterpreter.modelInterpreter(remoteModel: remoteModel)
        print("Model For you????")
        guard let modelPath = Bundle.main.path(
          forResource: "vendmachine",
          ofType: "tflite"
        ) else {
            print("No ModelPath for you :( ")
            return }
        let localModel = CustomLocalModel(modelPath: modelPath)
        
        interpreter = ModelInterpreter.modelInterpreter(localModel: localModel)
        
        print("LOCAL MODEL::::::::::", localModel)
        
        setupNotifications()
    }
    
    func setupNotifications(){
        
        NotificationCenter.default.addObserver(
            forName: .firebaseMLModelDownloadDidSucceed,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            print("GOT MODEL from FIREBASE!!!!!!!!!")
            guard let strongSelf = self,
                let userInfo = notification.userInfo,
                let model = userInfo[ModelDownloadUserInfoKey.remoteModel.rawValue]
                    as? RemoteModel,
                model.name == "cats_2019121518288"
                else { return }
            // The model was downloaded and is available on the device
            print("MODEL GOOD TO GO?????",strongSelf.interpreter)
            self!.interpreter = ModelInterpreter.modelInterpreter(remoteModel: model as! CustomRemoteModel)
            print("MODEL GOOD TO GO?????",strongSelf.interpreter)
        }

        NotificationCenter.default.addObserver(
            forName: .firebaseMLModelDownloadDidFail,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            print("OOOOOOOPS:::::: DID NOT GET  MODEL from FIREBASE!!!!!!!!!", notification)
            guard let strongSelf = self,
                let userInfo = notification.userInfo,
                let model = userInfo[ModelDownloadUserInfoKey.remoteModel.rawValue]
                    as? RemoteModel
                else { return }
            let error = userInfo[ModelDownloadUserInfoKey.error.rawValue]
            // ...
        }
    }
    
    
    func simpleRun(with uiImage: UIImage, completion: @escaping ((String) -> Void)) {
        
        print("Simple RUN")
        
        let inputs = ModelInputs()
        do {
            let data = uiImage.scaledData(with: CGSize(width: 150,height: 150),
                                          byteCount: 150*150*3*1,
                                          isQuantized: false) //float32 or uint8
            print("GOT DATA?????")
            try inputs.addInput(data)
            
            interpreter.run(inputs: inputs, options: ioOptions) { [weak self] (outputs, error) in
                
            print("INTERPRETED THE INPUT DATA")
               if error != nil {
                    print("Error running the model \(error.debugDescription)")
                    completion("NA")
                    return
               }
                do {
                    let output = try outputs!.output(index: 0) as? [[NSNumber]]
                    let probabilities = output?[0]
                    
                    print("outputs", output)
                    let catProb = probabilities![0]
                    let dogProb = probabilities![1]
                    let vendProb = probabilities![2]
                    
                    if vendProb.floatValue > 0.4 { // This imbalance in the categories is due to the number of data points for vending machines. TODO: Add proper weights when training the model.
                        completion(self?.labels[2] ?? "NA")
                    } else if catProb.floatValue >= dogProb.floatValue {
                        completion(self?.labels[0] ?? "NA")
                    } else if catProb.floatValue < dogProb.floatValue {
                        completion(self?.labels[1] ?? "NA")
                    }
               } catch let error as NSError {
                   print("Error in parsing the Output \(error.debugDescription)")
                   completion("NA")
               }
           }
        } catch {
            print("Simple Run Error:",error)
            completion("NA")
        }
    }
    
}


// MARK - Machine Learning calls
extension MLVisionViewrController {
    private static var categories = ["Unknown", "Home Goods", "Fashion Goods", "Food", "Places", "Plants"]
    
    // MARK: Run on-device object detection on an image

    func runObjectDetection(with image: UIImage) {
      let visionImage = VisionImage(image: image)
      objectDetector.process(visionImage) { objects, error in
        self.processResult(from: objects, error: error)
      }
    }

    // MARK: Process the object detection response

    private func processResult(from objects: [VisionObject]?, error: Error?) {
      removeDetectionAnnotations()
      guard error == nil else {
        let errorString = error?.localizedDescription ?? Constants.detectionNoResultsMessage
        print("Object detection failed with error: \(errorString)")
        return
      }
    

      guard let objects = objects, !objects.isEmpty else {
        print("On-Device object detector returned no results.")
        return
      }

      let transform = self.transformMatrix()
        
       

      objects.forEach { object in
        print(">>>>>>>>",object, object.classificationCategory.rawValue)
        let img = self.imageView!.image
        
        guard let _image = img?.cgImage else {
                   return
               }
        
        
        self.visionModel!.simpleRun(with: UIImage(cgImage:_image.cropping(to: object.frame)!)) {[ weak self ] label in

        
            self!.drawFrame(object.frame, in: .green, transform: transform)

        let transformedRect = object.frame.applying(transform)
        UIUtilities.addRectangle(
          transformedRect,
          to: self!.annotationOverlayView,
          color: .green
        )

        let labelView = UILabel(frame: transformedRect)
        labelView.numberOfLines = 2
        labelView.text = "Category: \(label)" //\nConfidence: \(object.confidence ?? 0)
        labelView.adjustsFontSizeToFitWidth = true
            self!.annotationOverlayView.addSubview(labelView)
        }
      }
    }
    
}


// MARK: - Image Layouting and Tweaking

extension MLVisionViewrController {
    
    private func drawFrame(_ frame: CGRect, in color: UIColor, transform: CGAffineTransform) {
           let transformedRect = frame.applying(transform)
           UIUtilities.addRectangle(
             transformedRect,
             to: self.annotationOverlayView,
             color: color
           )
         }

         private func drawPoint(_ point: VisionPoint, in color: UIColor, transform: CGAffineTransform) {
           let transformedPoint = pointFrom(point).applying(transform);
           UIUtilities.addCircle(atPoint: transformedPoint,
                                 to: annotationOverlayView,
                                 color: color,
                                 radius: Constants.smallDotRadius)
         }

         private func pointFrom(_ visionPoint: VisionPoint) -> CGPoint {
           return CGPoint(x: CGFloat(visionPoint.x.floatValue), y: CGFloat(visionPoint.y.floatValue))
         }

         /// Updates the image view with a scaled version of the given image.
        func updateImageView(with image: UIImage) {
           let orientation = UIApplication.shared.statusBarOrientation
           var scaledImageWidth: CGFloat = 0.0
           var scaledImageHeight: CGFloat = 0.0
           switch orientation {
           case .portrait, .portraitUpsideDown, .unknown:
             scaledImageWidth = imageView.bounds.size.width
             scaledImageHeight = image.size.height * scaledImageWidth / image.size.width
           case .landscapeLeft, .landscapeRight:
             scaledImageWidth = image.size.width * scaledImageHeight / image.size.height
             scaledImageHeight = imageView.bounds.size.height
           @unknown default:
               print("UNKNOWN ORIENTATION!")
           }
           DispatchQueue.global(qos: .userInitiated).async {
             // Scale image while maintaining aspect ratio so it displays better in the UIImageView.
             var scaledImage = image.scaledImage(
               with: CGSize(width: scaledImageWidth, height: scaledImageHeight)
             )
             scaledImage = scaledImage ?? image
             guard let finalImage = scaledImage else { return }
             DispatchQueue.main.async {
               self.imageView.image = finalImage
             }
           }
         }

        func transformMatrix() -> CGAffineTransform {
           guard let image = imageView.image else { return CGAffineTransform() }
           let imageViewWidth = imageView.frame.size.width
           let imageViewHeight = imageView.frame.size.height
           let imageWidth = image.size.width
           let imageHeight = image.size.height

           let imageViewAspectRatio = imageViewWidth / imageViewHeight
           let imageAspectRatio = imageWidth / imageHeight
           let scale = (imageViewAspectRatio > imageAspectRatio) ?
             imageViewHeight / imageHeight :
             imageViewWidth / imageWidth

           // Image view's `contentMode` is `scaleAspectFit`, which scales the image to fit the size of the
           // image view by maintaining the aspect ratio. Multiple by `scale` to get image's original size.
           let scaledImageWidth = imageWidth * scale
           let scaledImageHeight = imageHeight * scale
           let xValue = (imageViewWidth - scaledImageWidth) / CGFloat(2.0)
           let yValue = (imageViewHeight - scaledImageHeight) / CGFloat(2.0)

           var transform = CGAffineTransform.identity.translatedBy(x: xValue, y: yValue)
           transform = transform.scaledBy(x: scale, y: scale)
           return transform
         }

         /// Removes the detection annotations from the annotation overlay view.
        func removeDetectionAnnotations() {
           for annotationView in annotationOverlayView.subviews {
             annotationView.removeFromSuperview()
           }
         }
    
}



// MARK: - Fileprivate
fileprivate enum Constants {
  static let lineWidth: CGFloat = 3.0
  static let lineColor = UIColor.yellow.cgColor
  static let fillColor = UIColor.clear.cgColor
  static let smallDotRadius: CGFloat = 5.0
  static let largeDotRadius: CGFloat = 10.0
  static let detectionNoResultsMessage = "No results returned."
  static let failedToDetectObjectsMessage = "Failed to detect objects in image."
  static let maxRGBValue: Float32 = 255.0
  static let topResultsCount: Int = 5
}
