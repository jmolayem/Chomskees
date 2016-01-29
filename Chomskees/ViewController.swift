//
//  ViewController.swift
//  Project13
//
//  Created by Hudzilla on 15/09/2015.
//  Copyright © 2015 Paul Hudson. All rights reserved.
//

import UIKit
import Wit
import AVFoundation

extension ViewController : WitDelegate {
    
    func witDidGraspIntent(outcomes: [AnyObject]!, messageId: String!, customData: AnyObject!, error e: NSError!) {
        //
        if let error = e {
            print("error ", error.localizedDescription)
            return
        }
        
        let firstOutcome : NSDictionary = (outcomes[0] as! NSDictionary)
        let text : String = firstOutcome["_text"] as! String
        let intent : String = firstOutcome["intent"] as! String
        
         self.setFilterWithName(intent)
        
        //if let intentModel = self.dataController.intentsData[intent] {
            //intentLabel!.text = intentModel.intent
            //self.labelView!.text = intentModel.parking!
            //self.activatedTextView!.text = intentModel.email!
            //self.labelView!.text = " " + intentModel.phoneNumber!
            //self.textLabel!.text = text
            
            //self.speakFromIntent(intentModel)
            
        //} else {
            //self.textLabel!.text = ""
            //self.intentLabel!.text = ""
            //self.activatedTextView!.text = ""
            //self.labelView!.text = ""
        //}
        //self.navigationController?.pushViewController(ContactViewController:UIViewController, animated: true)
        
        //self.labelView!.sizeToFit(),
        //self.textLabel!.sizeToFit()
        
        //self.updateViewLayout()
    }
    
//    func updateViewLayout() {
//        
//        let screen : CGRect = UIScreen.mainScreen().bounds
//        
//        var textLabelFrame = self.textLabel!.frame
//        textLabelFrame.size.width = CGRectGetWidth(screen)
//        textLabelFrame.origin.y = CGRectGetMinY(self.witButton.frame) - CGRectGetHeight(textLabelFrame) - labelOffset
//        self.textLabel!.frame = textLabelFrame
//        
//        var labelViewFrame = self.labelView!.frame
//        labelViewFrame.size.width = CGRectGetWidth(screen)
//        self.labelView!.frame = labelViewFrame
//    }
    
    //func speakFromIntent(intentModel: IntentModel) {
    //let utterance = AVSpeechUtterance(string: intentModel.description!)
    //utterance.rate = 0.1
    
    //synthesizer?.speakUtterance(utterance)
}

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
	@IBOutlet weak var imageView: UIImageView!
	@IBOutlet weak var intensity: UISlider!

    let witButton : WITMicButton = WITMicButton()
    
	var currentImage: UIImage!
	var context: CIContext!
	var currentFilter: CIFilter!

	override func viewDidLoad() {
		super.viewDidLoad()

		title = "YACIFP"
		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "importPicture")

		context = CIContext(options: nil)
		currentFilter = CIFilter(name: "CISepiaTone")
        Wit.sharedInstance().delegate = self
        
        let screen : CGRect = UIScreen.mainScreen().bounds
        let rect : CGRect = CGRectMake(screen.size.width/2 - 50, 350, 80, 80)
        
        self.witButton.frame = rect
        self.view.addSubview(witButton)
	}

	func importPicture() {
		let picker = UIImagePickerController()
		picker.allowsEditing = true
		picker.delegate = self
		presentViewController(picker, animated: true, completion: nil)
	}

	func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
		var newImage: UIImage

		if let possibleImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
			newImage = possibleImage
		} else if let possibleImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
			newImage = possibleImage
		} else {
			return
		}

		dismissViewControllerAnimated(true, completion: nil)

		currentImage = newImage

		let beginImage = CIImage(image: currentImage)
		currentFilter.setValue(beginImage, forKey: kCIInputImageKey)

		applyProcessing()
	}

	func imagePickerControllerDidCancel(picker: UIImagePickerController) {
		dismissViewControllerAnimated(true, completion: nil)
	}

	@IBAction func changeFilter(sender: AnyObject) {
		let ac = UIAlertController(title: "Choose filter", message: nil, preferredStyle: .ActionSheet)
		ac.addAction(UIAlertAction(title: "CIBumpDistortion", style: .Default, handler: setFilter))
		ac.addAction(UIAlertAction(title: "CIGaussianBlur", style: .Default, handler: setFilter))
		ac.addAction(UIAlertAction(title: "CIPixellate", style: .Default, handler: setFilter))
		ac.addAction(UIAlertAction(title: "CISepiaTone", style: .Default, handler: setFilter))
		ac.addAction(UIAlertAction(title: "CITwirlDistortion", style: .Default, handler: setFilter))
		ac.addAction(UIAlertAction(title: "CIUnsharpMask", style: .Default, handler: setFilter))
		ac.addAction(UIAlertAction(title: "CIVignette", style: .Default, handler: setFilter))
		ac.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
		presentViewController(ac, animated: true, completion: nil)
	}

	func setFilter(action: UIAlertAction!) {
		//changed current filter from name; action.title! to use voice intent
        self.setFilterWithName(action.title!)
	}
    
    func setFilterWithName(filterName:String!) {
        currentFilter = CIFilter(name: filterName)
        
        let beginImage = CIImage(image: currentImage)
        currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
        
        applyProcessing()
    }

	@IBAction func save(sender: AnyObject) {
		UIImageWriteToSavedPhotosAlbum(imageView.image!, self, "image:didFinishSavingWithError:contextInfo:", nil)
	}

	@IBAction func intensityChanged(sender: AnyObject) {
		applyProcessing()
	}

	func applyProcessing() {
		let inputKeys = currentFilter.inputKeys

		if inputKeys.contains(kCIInputIntensityKey) { currentFilter.setValue(intensity.value, forKey: kCIInputIntensityKey) }
		if inputKeys.contains(kCIInputRadiusKey) { currentFilter.setValue(intensity.value * 200, forKey: kCIInputRadiusKey) }
		if inputKeys.contains(kCIInputScaleKey) { currentFilter.setValue(intensity.value * 10, forKey: kCIInputScaleKey) }
		if inputKeys.contains(kCIInputCenterKey) { currentFilter.setValue(CIVector(x: currentImage.size.width / 2, y: currentImage.size.height / 2), forKey: kCIInputCenterKey) }

		let cgimg = context.createCGImage(currentFilter.outputImage!, fromRect: currentFilter.outputImage!.extent)
		let processedImage = UIImage(CGImage: cgimg)

		self.imageView.image = processedImage
	}

	func image(image: UIImage, didFinishSavingWithError error: NSError?, contextInfo:UnsafePointer<Void>) {
		if error == nil {
			let ac = UIAlertController(title: "Saved!", message: "Your altered image has been saved to your photos.", preferredStyle: .Alert)
			ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
			presentViewController(ac, animated: true, completion: nil)
		} else {
			let ac = UIAlertController(title: "Save error", message: error?.localizedDescription, preferredStyle: .Alert)
			ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
			presentViewController(ac, animated: true, completion: nil)
		}
	}
}

