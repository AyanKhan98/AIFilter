//
//  ContentView.swift
//  AIFilter
//
//  Created by Ayan khan on 01/03/26.
//
import PhotosUI
import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct ContentView: View {
    @State private var processedImage: Image?
    @State private var photoPicked: PhotosPickerItem?
    @State private var currentFilter: CIFilter = CIFilter.sepiaTone()
    @State private var filterIntensity = 0.5
    @State private var showFilter: Bool = false
    let context = CIContext()
    var body: some View {
        NavigationStack(){
            VStack {
                Spacer()
                
                PhotosPicker(selection: $photoPicked, matching: .images) {
                    if let processedImage{
                        processedImage
                            .resizable()
                            .scaledToFit()
                    }
                    else {
                        ContentUnavailableView("No Image", systemImage: "photo.badge.plus", description: Text("Tap to pick a photo"))
                    }
                }
                Spacer()
                Slider(value: $filterIntensity, in: 0...1, step: 0.01)
                    .padding()
                    .onChange(of: filterIntensity) { _ in
                        applyProcessing()
                    }
                .onChange(of: photoPicked) { _, _ in
                    loadImage()
                }
                Button("Change filter")
                {
                    showFilter.toggle()
                }
            }
            .padding()
            .confirmationDialog("Choose Filter", isPresented:$showFilter)
            {
                Button("sepiaTone"){ setFilter(CIFilter.sepiaTone())}
                Button("boxBlur"){ setFilter(CIFilter.boxBlur())}
                Button("pixellate"){ setFilter(CIFilter.pixellate())}
                Button("colorCurves"){ setFilter(CIFilter.colorCurves())}
                Button("Cancel", role: .cancel){ showFilter.toggle()}
            }
        }
    }
    
    func setFilter(_ filter: CIFilter) {
        self.currentFilter = filter
        loadImage()
        showFilter.toggle()
    }
    @MainActor
    func applyProcessing() {
        var inputKeys = currentFilter.inputKeys
        
        if inputKeys.contains(kCIInputIntensityKey) {
            currentFilter.setValue(filterIntensity, forKey: kCIInputIntensityKey)
        }
        if inputKeys.contains(kCIInputRadiusKey) {
            currentFilter.setValue(filterIntensity * 200, forKey: kCIInputRadiusKey)
        }
        if inputKeys.contains(kCIInputScaleKey) {
            currentFilter.setValue(filterIntensity * 10, forKey: kCIInputScaleKey)
        }

        guard let outputImage = currentFilter.outputImage else { return }
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return }

        let uiImage = UIImage(cgImage: cgImage)
        processedImage = Image(uiImage: uiImage)
    }
    
    func loadImage() {
        Task {
            guard let imageData = try await photoPicked?.loadTransferable(type: Data.self) else {
                return
            }
            guard let inputImage = UIImage(data: imageData) else {
                return
            }
            
            let beginImage = CIImage(image: inputImage)
            currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
            applyProcessing()
            
        }
    }
}

#Preview {
    ContentView()
}
