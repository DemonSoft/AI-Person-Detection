//
//  ContentVM.swift
//  PersonDetect
//
//  Created by Dmitriy Soloshenko on 24.05.2024.
//

import Combine
import SwiftUI
import UIKit

class ContentVM : ObservableObject {
    
    // MARK: - Types
    
    // MARK: - Publishers
    @Published private (set) var result = ""

    // MARK: - Public properties
    
    // MARK: - Private properties
    private let mlTag        = "person"
    private var countObjects = 0

    /// A predictor instance that uses Vision and Core ML to generate prediction strings from a photo.
    private let imagePredictor = ImagePredictor()

    /// The largest number of predictions the main view controller displays the user.
    private let predictionsToShow    = 2

    // MARK: - Init
    init() {
    }
    
    deinit {
    }
    
    // MARK: - Public methods
    func picked(_ image: UIImage?) {
        guard let image = image else { return }
        self.countObjects = 0
        self.result       = ""

        DispatchQueue.global(qos: .userInitiated).async {
            self.imagePredictor.makePredictions(for: image, completionHandler: self.predictHandler)
        }
    }

    // MARK: - Private methods
    
    // MARK: Image prediction methods
    private func predictHandler(_ prediction: ImagePredictor.Prediction) {
        
        var result = ""

        for item in prediction.items {
            result += "\(item.name.capitalized) detected\nwith \(String(format: "%.2f",item.confidence)) confidence.\n"
        }
        
        
        let personCount = prediction.items.filter { $0.name == self.mlTag }.count
        
        switch personCount {
            case 0: result += "\nMISTAKE"
            case 1: result += "\nSUCCESS"
        default:
            result += "\nMORE THAN ONE PERSON"
        }
        
        self.result = result
        
        
    }

}
