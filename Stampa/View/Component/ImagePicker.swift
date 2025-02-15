//
//  ImagePickewr.swift
//  Stampa
//
//  Created by a on 2/15/25.
//

import SwiftUI
import UIKit

struct ImagePicker: UIViewControllerRepresentable {
  @Binding var image: UIImage?
  var sourceType: UIImagePickerController.SourceType = .photoLibrary
  
  @Environment(\.presentationMode) private var presentationMode
  
  // Coordinator を作成して、UIImagePickerControllerDelegate と UINavigationControllerDelegate を実装
  class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    let parent: ImagePicker
    
    init(_ parent: ImagePicker) {
      self.parent = parent
    }
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
      if let selectedImage = info[.originalImage] as? UIImage {
        parent.image = selectedImage
      }
      parent.presentationMode.wrappedValue.dismiss()
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      parent.presentationMode.wrappedValue.dismiss()
    }
  }
  
  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }
  
  func makeUIViewController(context: Context) -> UIImagePickerController {
    let picker = UIImagePickerController()
    picker.sourceType = sourceType
    picker.delegate = context.coordinator
    return picker
  }
  
  func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}
