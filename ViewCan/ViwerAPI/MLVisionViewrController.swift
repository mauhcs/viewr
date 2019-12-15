//
//  MLVisionViewrController.swift
//  ViewCan
//
//  Created by Mauricio Hernandes on 2019/12/14.
//  Copyright © 2019 Mauricio Hernandes. All rights reserved.
//


import UIKit
//import PromiseKit
import Firebase
import FirebaseMLVisionObjectDetection


// QRCodeViewController
class MLVisionViewrController: UIViewController, UINavigationControllerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    
    /// An overlay view that displays detection annotations.
    lazy var annotationOverlayView: UIView = {
      precondition(isViewLoaded)
      let annotationOverlayView = UIView(frame: .zero)
      annotationOverlayView.translatesAutoresizingMaskIntoConstraints = false
      return annotationOverlayView
    }()

    /// An image picker for accessing the photo library or camera.
    var imagePicker = UIImagePickerController()

    // MARK: Create an ObjectDetector

    private lazy var vision = Vision.vision()
    private lazy var options: VisionObjectDetectorOptions = {
      let options = VisionObjectDetectorOptions()
      options.shouldEnableClassification = true
      options.shouldEnableMultipleObjects = true
      options.detectorMode = .singleImage
      return options
    }()

    lazy var objectDetector = vision.objectDetector(options: options)
    
    var visionModel: VisionModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupImageView()
        setupImagePicker()
        visionModel = VisionModel()
    }
    
    func setupImagePicker(){
        let _delegate = self as? UIImagePickerControllerDelegate & UINavigationControllerDelegate
        if _delegate != nil {
            imagePicker.delegate = _delegate!
        }
        if UIImagePickerController.isCameraDeviceAvailable(.front) ||
          UIImagePickerController.isCameraDeviceAvailable(.rear) {
          imagePicker.sourceType = .camera
        } else {
          imagePicker.sourceType = .photoLibrary
        }
    }
    
    func setupImageView() {
        imageView.addSubview(annotationOverlayView)
        NSLayoutConstraint.activate([
          annotationOverlayView.topAnchor.constraint(equalTo: imageView.topAnchor),
          annotationOverlayView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
          annotationOverlayView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
          annotationOverlayView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
          ])
    }
    
    // MARK: Button Actions:

    @IBAction func openCamera(_ sender: Any) {
        present(imagePicker, animated: true)
    }

    // MARK: Actions

    @IBAction func didTapDetectObjects(_ sender: Any) {
        runObjectDetection(with: imageView.image!)
    }
    
    @IBAction func tapFaceDetect(_ sender: Any) {
        guard (visionModel != nil) else {
            print("No VisionModel")
            return
        }
        visionModel!.simpleRun(with: imageView.image!) {label in
            print("This is a:", label)
        }
    }
    
}

// MARK: - UIImagePickerControllerDelegate

extension MLVisionViewrController: UIImagePickerControllerDelegate {
    
    func imagePickerController (_ picker: UIImagePickerController, didFinishPickingMediaWithInfo
        info: [UIImagePickerController.InfoKey : Any]){
        removeDetectionAnnotations()
        // check if an image was selected,
        // since a images are not the only media type that can be selected
        if let img = info[.originalImage] {
            let _img = img as? UIImage
            if _img != nil {
                updateImageView(with: _img!)
            }
        }
        dismiss(animated: true)
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



