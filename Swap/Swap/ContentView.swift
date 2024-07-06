//
//  ContentView.swift
//  Swap
//
//  Created by Fenuku kekeli on 7/5/24.
//
import SwiftUI
import Vision
import UIKit

struct ContentView: View {
    @State private var image: UIImage? = nil
    @State private var recognizedText: String = ""
    @State private var isImagePickerPresented: Bool = false
    @State private var isProcessing: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)

                VStack {
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 300)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                            .padding()
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.5))
                    } else {
                        Button(action: {
                            isImagePickerPresented = true
                        }) {
                            Image("camera")
                                .resizable()
                                .frame(width: 200, height: 200)
                                .background(Color.gray.opacity(0.5))
                                .cornerRadius(10)
                                .shadow(radius: 5)
                                .padding()
                        }
                    }

                    if isProcessing {
                        ProgressView("Processing...")
                            .padding()
                            .transition(.scale)
                            .animation(.easeInOut(duration: 0.5))
                    }

                    ScrollView {
                        Text(recognizedText)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                            .padding()
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.5))
                    }
                }
                .navigationTitle("Image to Text")
                .bold()
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(trailing: Button(action: {
                    clearImage()
                }) {
                    Image(systemName: "trash")
                       
                        .font(.title2)
                        .padding()
                        .foregroundColor(.red)
                }.disabled(image == nil))
                .sheet(isPresented: $isImagePickerPresented) {
                    ImagePicker(image: $image, recognizedText: $recognizedText, isProcessing: $isProcessing, showAlert: $showAlert, alertMessage: $alertMessage)
                }
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                }
            }
        }
    }

    private func clearImage() {
        withAnimation {
            image = nil
            recognizedText = ""
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var recognizedText: String
    @Binding var isProcessing: Bool
    @Binding var showAlert: Bool
    @Binding var alertMessage: String

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: ImagePicker

        init(parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
                parent.isProcessing = true
                recognizeText(from: uiImage)
            }
            picker.dismiss(animated: true)
        }

        func recognizeText(from image: UIImage) {
            guard let cgImage = image.cgImage else {
                DispatchQueue.main.async {
                    self.parent.alertMessage = "Unable to get CGImage from UIImage."
                    self.parent.showAlert = true
                    self.parent.isProcessing = false
                }
                return
            }

            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            let request = VNRecognizeTextRequest { (request, error) in
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    DispatchQueue.main.async {
                        self.parent.alertMessage = "Unable to get text observations."
                        self.parent.showAlert = true
                        self.parent.isProcessing = false
                    }
                    return
                }

                if observations.isEmpty {
                    DispatchQueue.main.async {
                        self.parent.alertMessage = "No text found in the image."
                        self.parent.showAlert = true
                        self.parent.isProcessing = false
                    }
                    return
                }

                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")

                DispatchQueue.main.async {
                    withAnimation {
                        self.parent.recognizedText = recognizedText
                        self.parent.isProcessing = false
                    }
                }
            }

            do {
                try requestHandler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    self.parent.alertMessage = "Unable to perform the requests: \(error)."
                    self.parent.showAlert = true
                    self.parent.isProcessing = false
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
