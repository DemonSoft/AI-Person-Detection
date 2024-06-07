//
//  ImagePredictor.swift
//  PersonDetect
//
//  Created by Dmitriy Soloshenko on 24.05.2024.
//

import Vision
import UIKit

class ImagePredictor {
    
    private var requests = [VNRequest]()
    var predictions: [VNRecognizedObjectObservation] = []
    var request: VNCoreMLRequest?

    static func createImageClassifier() -> VNCoreMLModel {
        let defaultConfig = MLModelConfiguration()
        let imageClassifierWrapper = try? YOLOv3TinyInt8LUT(configuration: defaultConfig)

        guard let imageClassifier = imageClassifierWrapper else {
            fatalError("App failed to create an image classifier model instance.")
        }

        let imageClassifierModel = imageClassifier.model

        guard let imageClassifierVisionModel = try? VNCoreMLModel(for: imageClassifierModel) else {
            fatalError("App failed to create a `VNCoreMLModel` instance.")
        }

        return imageClassifierVisionModel
    }

    private static let imageClassifier = createImageClassifier()

    /// Stores a classification name and confidence for an image classifier's prediction.
    /// - Tag: Prediction
    struct Prediction {
        struct Item {
            let name: String
            let confidence: Double
        }
        
        let items:[Item]
    }

    /// The function signature the caller must provide as a completion handler.
    typealias ImagePredictionHandler = (_ prediction: Prediction) -> Void

    /// A dictionary of prediction handler functions, each keyed by its Vision request.
    private var predictionHandler:ImagePredictionHandler?

    /// Generates a new request instance that uses the Image Predictor's image classifier model.
    private func createImageClassificationRequest() -> VNImageBasedRequest {

        let request = VNCoreMLRequest(model: ImagePredictor.imageClassifier,
                                  completionHandler: visionRequestDidComplete)
        request.imageCropAndScaleOption = .scaleFill

        return request
    }

    func makePredictions(for photo: UIImage, completionHandler: @escaping ImagePredictionHandler) {
        let orientation = CGImagePropertyOrientation(photo.imageOrientation)

        guard let photoImage = photo.cgImage else {
            fatalError("Photo doesn't have underlying CGImage.")
        }

        let request                 = self.createImageClassificationRequest()
        self.predictionHandler      = completionHandler

        let handler                 = VNImageRequestHandler(cgImage : photoImage, orientation : orientation)
        self.requests               = [request]
        
        do {
            try handler.perform(self.requests)
        } catch {
            print("Vision was unable to make a prediction...\n\n\(error.localizedDescription)")
        }
    }

    private func visionRequestDidComplete(request: VNRequest, error: Error?) {
        if let predictions = request.results as? [VNRecognizedObjectObservation] {
            self.predictions = predictions
            
            let array = self.predictions
                .compactMap { $0.labels.first }
                .compactMap { Prediction.Item(name: $0.identifier, confidence: Double($0.confidence)) }
            
            let prediction = Prediction(items: array)
            DispatchQueue.main.async { [weak self] in
                self?.predictionHandler?(prediction)
            }
        }
    }
}
