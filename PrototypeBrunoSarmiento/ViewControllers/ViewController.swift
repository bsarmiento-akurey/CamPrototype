//
//  ViewController.swift
//  PrototypeBrunoSarmiento
//
//  Created by Bruno Sarmiento on 3/13/18.
//  Copyright © 2018 Akurey. All rights reserved.
//

import AVFoundation
import UIKit

class ViewController: UIViewController {
    // MARK: - Outlets
    // Image views
    @IBOutlet weak var previewImage: UIImageView!
    // Buttons
    @IBOutlet weak var switchCameraButton: UIButton!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var firstFilterButton: UIButton!
    @IBOutlet weak var secondFilterButton: UIButton!
    @IBOutlet weak var downloadButton: UIButton!
    // Labels
    @IBOutlet weak var helloWordLabel: UILabel!
    // Constraints
    @IBOutlet weak var verticalConstraintForLabel: NSLayoutConstraint!
    @IBOutlet weak var horizontalConstraintForLabel: NSLayoutConstraint!
    
    // MARK: - Variables
    private var captureSession = AVCaptureSession()
    private var captureDevice: AVCaptureDevice?
    private var currentCameraPosition: AVCaptureDevice.Position = .back
    private var cameraInitialized = false
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var photoOutput: AVCapturePhotoOutput?
    private var originalPictureTaken: UIImage?
    private var textOriginX: CGFloat = 0
    private var textOriginY: CGFloat = 0
    private var viewMidX: CGFloat = 0
    private var viewMidY: CGFloat = 0
    private var textSize: CGFloat = 0
    private let filters = [#imageLiteral(resourceName: "filter1"), #imageLiteral(resourceName: "filter2")] // list of filter images
    private let noFilterIndex = -1
    private var currentFilterIndex = -1
    // Gesture recognizers
    private var panGestureForLabel: UIPanGestureRecognizer?
    private var pinchGestureForLabel: UIPinchGestureRecognizer?
    private var rightSwipeGestureForPreviewImage: UISwipeGestureRecognizer?
    private var leftSwipeGestureForPreviewImage: UISwipeGestureRecognizer?
    private var upSwipeGestureForPreviewImage: UISwipeGestureRecognizer?
    
    // MARK: - Override methods
    override func viewDidLoad() {
        super.viewDidLoad()
        // Call a function that will prepare the initial styles of the UI components
        self.setStyles()
        
        // Check for authorization of the camera
        self.checkAuthorization(forMediaType: .video) {
            [weak self]
            authorized in
            guard authorized else {
                print("App need permission to use camera...")
                return
            }
            self?.checkAuthorization(forMediaType: .audio, {
                [weak self]
                authorized in
                guard authorized else {
                    print("App need permission to use microphone...")
                    return
                }
                DispatchQueue.main.async {
                    self?.startCamera(position: .back)
                }
            })
        }
    }

    // MARK: - Methods
    // Starts the camera of the given position
    private func startCamera(position: AVCaptureDevice.Position) {
        captureSession.sessionPreset = .high
        
        if let videoDevice = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera] ,
                                                              mediaType: .video,
                                                              position: position).devices.first {
            self.captureDevice = videoDevice
            self.beginSession()
        }
    }
    
    // Centers the Hello World label by updating the constraints
    private func centerHelloWorldLabel() {
        self.verticalConstraintForLabel.constant = 0
        self.horizontalConstraintForLabel.constant = 0
    }
    
    // Set initial styles on different UI components
    private func setStyles() {
        // Initial styles of the Hello World label
        self.helloWordLabel.sizeToFit()
        self.helloWordLabel.backgroundColor = UIColor.blue
        self.centerHelloWorldLabel()
        self.addGesturesRecognizersToLabel()
        
        // Add the gesture recognizers to the preview images (the swipes)
        self.addGesturesRecognizersToPreviewImage()
        
        // Saves the mid x and mid y coordinates
        self.viewMidX = self.helloWordLabel.frame.midX
        self.viewMidY = self.helloWordLabel.frame.midY
        
        // Hide the controls that must be shown when a picture is taken. Show controls that should be displayed to take a picture.
        self.helloWordLabel.isHidden = true
        self.onScreenPictureControls(shouldBeHidden: true)
    }
    
    private func beginSession() {
        guard let videoCaptureDevice = self.captureDevice else {
            // TODO: Add error
            print("no capture device")
            return
        }
        do {
            captureSession = AVCaptureSession()
            captureSession.sessionPreset = .high
            
            try captureSession.addInput(AVCaptureDeviceInput(device: videoCaptureDevice))
            
            self.photoOutput = AVCapturePhotoOutput()
            
            if let photoOutput = self.photoOutput {
                if captureSession.canAddOutput(photoOutput) {
                    captureSession.addOutput(photoOutput)
                    photoOutput.isHighResolutionCaptureEnabled = true
                }
            }
            else {
                // TODO: add error
            }
            
        }
        catch {
            // TODO: add error
            print("at beginning session, error: \(error.localizedDescription)")
        }
        
        captureSession.startRunning()
        
        let newPreviewLayer =  AVCaptureVideoPreviewLayer(session: captureSession)
        if self.previewLayer != nil {
            self.view.layer.replaceSublayer(self.previewLayer!, with: newPreviewLayer)
        }
        
        self.previewLayer = newPreviewLayer
        if let previewLayer = self.previewLayer {
            self.view.layer.insertSublayer(previewLayer, at: 0)
            previewLayer.videoGravity = .resizeAspectFill
            let bounds = self.view.layer.bounds
            previewLayer.bounds = bounds
            previewLayer.position = CGPoint.init(x: bounds.midX , y: bounds.midY)
            
            if let connection = previewLayer.connection,
                connection.isVideoOrientationSupported {
                connection.videoOrientation = AVCaptureVideoOrientation.portrait
            }
        }
    }
    
    func checkAuthorization(forMediaType type: AVMediaType, _ completionHandler: @escaping ((_ authorized: Bool) -> Void)) {
        switch AVCaptureDevice.authorizationStatus(for: type) {
        case .authorized:
            //The user has previously granted access to the camera.
            completionHandler(true)
        case .notDetermined:
            // The user has not yet been presented with the option to grant video access so request access.
            AVCaptureDevice.requestAccess(for: type, completionHandler: {
                success in
                completionHandler(success)
            })
        case .denied,
             .restricted:
            // The user has previously denied access.
            completionHandler(false)
        }
    }
    
    // Adds the gesture recognizers to the Hello World label and enables the user interaction
    private func addGesturesRecognizersToPreviewImage() {
        rightSwipeGestureForPreviewImage = UISwipeGestureRecognizer(target: self, action: #selector(self.handleRightSwipeGestureOnPreviewImage))
        if let gesture = rightSwipeGestureForPreviewImage {
            gesture.direction = .right
            self.previewImage.addGestureRecognizer(gesture)
        }
        
        leftSwipeGestureForPreviewImage = UISwipeGestureRecognizer(target: self, action: #selector(self.handleLeftSwipeGestureOnPreviewImage))
        if let gesture = leftSwipeGestureForPreviewImage {
            gesture.direction = .left
            self.previewImage.addGestureRecognizer(gesture)
        }
        
        upSwipeGestureForPreviewImage = UISwipeGestureRecognizer(target: self, action: #selector(self.handleUpSwipeGestureOnPreviewImage))
        if let gesture = upSwipeGestureForPreviewImage {
            gesture.direction = .up
            self.previewImage.addGestureRecognizer(gesture)
        }
        
        self.previewImage.isUserInteractionEnabled = true
    }
    
    // Adds the gesture recognizers to the Hello World label and enables user interaction
    private func addGesturesRecognizersToLabel() {
        panGestureForLabel = UIPanGestureRecognizer(target: self, action: #selector(self.handlePanGestureOnLabel))
        if let gesture = panGestureForLabel {
            gesture.maximumNumberOfTouches = 2
            self.helloWordLabel.addGestureRecognizer(gesture)
        }
        
        pinchGestureForLabel = UIPinchGestureRecognizer(target: self, action: #selector(self.handlePinchGestureOnLabel))
        if let pinchGesture = pinchGestureForLabel {
            self.helloWordLabel.addGestureRecognizer(pinchGesture)
        }
        
        self.helloWordLabel.isUserInteractionEnabled = true
    }
    
    // Changes the preview image to be displayed
    func changePreviewImage(with newImage: UIImage) {
        self.previewImage.image = newImage
    }
    
    // Toggles the camera, between front and back
    func toggleCameraPosition() -> AVCaptureDevice.Position {
        self.currentCameraPosition =  self.currentCameraPosition == .back ? .front : .back
        return self.currentCameraPosition
    }
    
    // Adds a filter passed by parameter to the last picture taken with the camera
    func addFilterToOriginalPictureTaken(filter: UIImage) -> UIImage? {
        if let picture = self.originalPictureTaken {
            let size = CGSize(width: picture.size.width, height: picture.size.height)
            UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
            
            picture.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            filter.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            
            let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            return newImage
        }
        else {
            return nil
        }
    }
    
    // Applies a new filter every time is called, in a circular direction.
    func applyFilter(inDirection direction: NavigationDirection) {
        switch direction {
        case .Next:
            self.currentFilterIndex += 1
        case .Previous:
            self.currentFilterIndex -= 1
        case .Current:
            break
        }

        // Adjust index in case of being out of bounds
        if self.currentFilterIndex >= self.filters.count {
            self.currentFilterIndex = self.noFilterIndex
        }
        else if self.currentFilterIndex < self.noFilterIndex {
            self.currentFilterIndex = self.filters.count - 1
        }
        
        //
        if self.currentFilterIndex == self.noFilterIndex {
            if let picture = self.originalPictureTaken {
                self.changePreviewImage(with: picture)
            }
        }
        else {
            let filterToBeApplied = self.filters[self.currentFilterIndex]
            if let pictureWithFilter = self.addFilterToOriginalPictureTaken(filter: filterToBeApplied) {
                self.changePreviewImage(with: pictureWithFilter)
            }
            else {
                // TODO: Add error
            }
        }
    }
    
    // Function called when a picture is called (changes the preview, activate controls, etc)
    func photoCaptured(_ image: UIImage) {
        self.changePreviewImage(with: image)
        self.originalPictureTaken = image
        self.onScreenPictureControls(shouldBeHidden: false)
    }
    
    // Show or hide the picture controls or the controls to take it
    func onScreenPictureControls(shouldBeHidden hidden: Bool) {
        // Picture taken controls
        self.deleteButton.isHidden = hidden
        self.previewImage.isHidden = hidden
        self.firstFilterButton.isHidden = hidden
        self.secondFilterButton.isHidden = hidden
        self.downloadButton.isHidden = hidden
        // Controls to take pictures
        self.switchCameraButton.isHidden = !hidden
        self.recordButton.isHidden = !hidden
    }

    
    // MARK: - Gesture recognizers handlers
    // On swipe right in the preview image, applies the previous filter
    @objc private func handleRightSwipeGestureOnPreviewImage() {
        self.applyFilter(inDirection: .Previous)
    }
    
    // On swipe left in the preview image, applies the next filter
    @objc private func handleLeftSwipeGestureOnPreviewImage() {
        self.applyFilter(inDirection: .Next)
    }
    
    // On swipe up, the picture is flipped
    @objc private func handleUpSwipeGestureOnPreviewImage() {
        self.originalPictureTaken = self.originalPictureTaken?.withHorizontallyFlippedOrientation()
        self.applyFilter(inDirection: .Current)
    }
    
    // Moves the hello world text as the user does the pan gesture over it
    @objc func handlePanGestureOnLabel() {
        if let panGesture = panGestureForLabel {
            // If the gesture is beginning, saves the coordinates where the label started
            if panGesture.state == .began {
                self.textOriginX = self.helloWordLabel.frame.origin.x
                self.textOriginY = self.helloWordLabel.frame.origin.y
            }
            
            // Updates the position of the label
            let translation = panGesture.translation(in: self.view)
            var frame = self.helloWordLabel.frame
            frame.origin.x = self.textOriginX + translation.x
            frame.origin.y = self.textOriginY + translation.y
            self.helloWordLabel.frame = frame
            
            // If the gesture finishes, saves the coordinates where it was at the end of the gesture and updates the constraints
            if panGesture.state == .ended {
                self.verticalConstraintForLabel.constant = self.helloWordLabel.frame.midY - self.viewMidY
                self.horizontalConstraintForLabel.constant = self.helloWordLabel.frame.midX - self.viewMidX
                self.textOriginX = self.helloWordLabel.frame.origin.x
                self.textOriginY = self.helloWordLabel.frame.origin.y
            }
        }
    }
    
    // Makes bigger/smaller the label while the user pinch over it
    @objc func handlePinchGestureOnLabel() {
        if let pinchGesture = pinchGestureForLabel {
            if pinchGesture.state == .began {
                // Saves the size of the font, to make the increment linear, not exponential
                self.textSize = self.helloWordLabel.font.pointSize
            }
            
            // Updates the size of the font
            self.helloWordLabel.font = self.helloWordLabel.font.withSize(self.textSize * pinchGesture.scale)
            self.helloWordLabel.sizeToFit()
        }
    }

    // Function called when the image is saved on the gallery
    @objc private func imageSaved(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if error == nil {
            // Shows and alert indicating that the image was saved successfully
            AlertManager.showAlert(from: self, withTitle: "Image saved succesfully!", andMessage: nil, alertActions: [AlertManager.okAction()])
        }
    }
    
    // MARK: - IBActions
    @IBAction func clickOnDownloadButton(_ sender: Any) {
        // Combine the label and the picture with/without filter and saves it in the photo album
        if let picture = self.previewImage.image {
            let uiLabelImage = UIImage.imageWithLabel(label: self.helloWordLabel)
            
            let size = CGSize(width: picture.size.width, height: picture.size.height)
            UIGraphicsBeginImageContextWithOptions(size, false, 0.0)

            let ratio = size.width / self.view.frame.size.width
            
            picture.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            uiLabelImage.draw(in: CGRect(x: self.helloWordLabel.frame.origin.x * ratio, y: self.helloWordLabel.frame.origin.y * ratio,
                                            width: self.helloWordLabel.frame.size.width * ratio, height: self.helloWordLabel.frame.size.height * ratio))

            let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            
            UIImageWriteToSavedPhotosAlbum(newImage, self, #selector(ViewController.imageSaved(_:didFinishSavingWithError:contextInfo:)), nil)
        }
    }
    
    // Applies a filter like swiping left would do it
    @IBAction func clickOnFirstFilterButton(_ sender: Any) {
        self.applyFilter(inDirection: .Next)
    }
    
    @IBAction func clickOnSecondFilterButton(_ sender: Any) {
        // Show/hide the hello world label and it centers it
        self.helloWordLabel.isHidden = !self.helloWordLabel.isHidden
        self.centerHelloWorldLabel()
    }
    
    // Take a picture
    @IBAction func clickOnRecordButton(_ sender: Any) {
        let photoSettings = AVCapturePhotoSettings()
        photoSettings.isHighResolutionPhotoEnabled = true
        
        if let firstAvailablePreviewPhotoPixelFormatTypes = photoSettings.availablePreviewPhotoPixelFormatTypes.first {
            photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: firstAvailablePreviewPhotoPixelFormatTypes]
        }
        
        if let photoOutput = self.photoOutput {
            photoOutput.capturePhoto(with: photoSettings, delegate: self)
        }
    }
    
    // Discard the picture taken and resets the controls
    @IBAction func clickOnDeleteVideoButton(_ sender: Any) {
        self.originalPictureTaken = nil
        self.onScreenPictureControls(shouldBeHidden: true)
        self.helloWordLabel.isHidden = true
        self.currentFilterIndex = self.noFilterIndex
    }
    
    // Switch cameras
    @IBAction func clickOnChangeCameraButton(_ sender: Any) {
        DispatchQueue.main.async {
            self.startCamera(position: self.toggleCameraPosition())
        }
    }
}


// MARK: - AVCapturePhotoCaptureDelegate Methods
extension ViewController: AVCapturePhotoCaptureDelegate {
    // Methods called when a picture is taken
    func photoOutput(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        
        if let error = error {
            print("Error capturing photo: \(error)")
        } else {
            if let sampleBuffer = photoSampleBuffer, let previewBuffer = previewPhotoSampleBuffer, let dataImage = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {
                if let image = UIImage(data: dataImage) {
                    if self.currentCameraPosition == .front {
                        if let ciImage = CIImage(image: image) {
                            let newImage = UIImage(ciImage: ciImage, scale: image.scale, orientation: .leftMirrored)
                            if let dataImage = newImage.png,
                                let image = UIImage(data: dataImage) {
                                // Some actions need to be done when the picture is taken, like hide buttons shows others, change the preview..
                                self.photoCaptured(image)
                                return
                            }
                        }
                    }
                    else {
                        self.photoCaptured(image)
                        return
                    }
                }
            }
        }
        
    }
    
    @available(iOS 11.0, *)
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let data = photo.fileDataRepresentation(),
            var image =  UIImage(data: data) {
            
            if self.currentCameraPosition == .front {
                if let ciImage = CIImage(image: image) {
                    image = UIImage(ciImage: ciImage, scale: image.scale, orientation: .leftMirrored)
                    if let dataImage = image.png,
                        let image = UIImage(data: dataImage) {
                        // Some actions need to be done when the picture is taken, like hide buttons shows others, change the preview..
                        self.photoCaptured(image)
                        return
                    }
                }
            }
            else {
                self.photoCaptured(image)
                return
            }
        }
        
    }
}
