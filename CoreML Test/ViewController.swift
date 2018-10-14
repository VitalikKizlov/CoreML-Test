//
//  ViewController.swift
//  CoreML Test
//
//  Created by Vitalik Kizlov on 10/14/18.
//  Copyright © 2018 Vitalik Kizlov. All rights reserved.
//

import UIKit
import AVKit
import Vision


class ViewController: UIViewController {
    
    @IBOutlet weak var textLabel: UILabel!
    
    
    fileprivate var captureSession: AVCaptureSession!

    override func viewDidLoad() {
        super.viewDidLoad()
        prepareCamera()
        prepareBufferDelegate()
    }
    
    // MARK: - Prepare Camera
    
    fileprivate func prepareCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        guard let captureDevice = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        captureSession.addInput(input)
        captureSession.startRunning()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
    }
    
    fileprivate func prepareBufferDelegate() {
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
    }

}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        guard let model = try? VNCoreMLModel(for: Resnet50().model) else { return }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let results = request.results as? [VNClassificationObservation] else { return }
            if let first = results.first {
                DispatchQueue.main.async {
                    self.textLabel.text = "\(first.identifier), \(first.confidence * 100)%"
                }
            }
        }
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
    
}

