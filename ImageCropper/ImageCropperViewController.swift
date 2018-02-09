//
//  ImageCropperViewController.swift
//  ImageCropper
//
//  Created by astghik on 2/7/18.
//

import UIKit

class ImageCropperViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: - Properties
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var cropView: UIView!
    @IBOutlet weak var selectImageLabel: UILabel!
    
    
    // MARK - ViewController Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        drowShape(around: cropView, by: UIColor.black)
    }
    
    
    // MARK: - Actions
    
    @IBAction func moveImage(_ sender: UIPanGestureRecognizer) {
        guard sender.view != nil else { return }
        
        if sender.state == .began || sender.state == .changed {
            let translation = sender.translation(in: sender.view)
            sender.view!.center = CGPoint(x: sender.view!.center.x + translation.x, y: sender.view!.center.y + translation.y)
            sender.setTranslation(CGPoint.zero, in: sender.view)
        }
    }
    
    @IBAction func zoomImage(_ sender: UIPinchGestureRecognizer) {
        guard sender.view != nil else { return }
        
        if sender.state == .began || sender.state == .changed {
            sender.view?.transform = (sender.view?.transform.scaledBy(x: sender.scale, y: sender.scale))!
            sender.scale = 1.0
        }
    }
    
    @IBAction func rotateImage(_ sender: UIRotationGestureRecognizer) {
        guard sender.view != nil else { return }
        
        if sender.state == .began || sender.state == .changed {
            sender.view?.transform = sender.view!.transform.rotated(by: sender.rotation)
            sender.rotation = 0
        }
    }
    
    @IBAction func selectImage(_ sender: UITapGestureRecognizer) {
        if imageView.image == nil {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            present(imagePicker, animated: true, completion: nil)
        }
    }
    
    @IBAction func saveImage() {
        guard imageView.image != nil else { return }
        
        if let croppedImage = cropImage(cropViewFrame: cropView.frame, imageView: imageView) {
            if saveImage(image: croppedImage) {
              //  showSuccessMessage()
            }
        }
    }
    
    
    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imageView.image = pickedImage
            selectImageLabel.isHidden = true
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    
    //MARK: - Private Methods
    
    private func drowShape(around view: UIView, by color: UIColor) {
        let viewBorder = CAShapeLayer()
        viewBorder.strokeColor = color.cgColor
        viewBorder.lineDashPattern = [10, 10]
        viewBorder.frame = view.bounds
        viewBorder.fillColor = nil
        viewBorder.path = UIBezierPath(rect: view.bounds).cgPath
        view.layer.addSublayer(viewBorder)
        view.backgroundColor = UIColor(white: 1, alpha: 0)
        view.layer.zPosition = 1
    }
    
    private func croppingArea(cropViewFrame: CGRect, imageView: UIImageView) -> CGRect? {
        let scaleX = (imageView.image?.size.width)! / imageView.frame.width
        let scaleY = (imageView.image?.size.height)! / imageView.frame.height
        
        let x: CGFloat = (cropViewFrame.origin.x - imageView.frame.origin.x) * scaleX
        let y: CGFloat = (cropViewFrame.origin.y - imageView.frame.origin.y) * scaleY
        let width = cropViewFrame.width * scaleX
        let height = cropViewFrame.height * scaleY
        
        let rect = CGRect(x: x, y: y, width: width, height: height)
        return rect
    }
    
    private func cropImage(cropViewFrame: CGRect, imageView: UIImageView) -> UIImage? {
        if let croppingArea = croppingArea(cropViewFrame: cropViewFrame, imageView: imageView) {
            let zoom =  cropViewFrame.width / imageView.frame.width
            imageView.transform = imageView.transform.concatenating(CGAffineTransform(scaleX: zoom, y: zoom))
            
            //let radians = atan2(imageView.transform.b, imageView.transform.a)
            //let degrees = radians * CGFloat(180 / Double.pi)
            //let rotation = CGAffineTransform(rotationAngle: degrees)
            //let rotatedCroppingArea = croppingArea.applying(rotation)
            
            let croppedCGImage = imageView.image?.cgImage?.cropping(to: croppingArea)
            let croppedImage = UIImage(cgImage: croppedCGImage!)
            self.imageView.image = croppedImage
            return croppedImage
        } else { return nil }
    }
    
    private func saveImage(image: UIImage) -> Bool {
        guard let data = UIImageJPEGRepresentation(image, 1) ?? UIImagePNGRepresentation(image),
            let directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) as NSURL else { return false }
        do {
            try data.write(to: directory.appendingPathComponent("croppedImage.png")!)
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
    
    private func showSuccessMessage() {
        let message = UIAlertController(title: "Success", message: "Cropped image saved", preferredStyle: UIAlertControllerStyle.alert)
        message.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
        self.present(message, animated: true, completion: nil)
    }
}
