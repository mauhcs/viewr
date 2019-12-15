//
//  AppStoryboard.swift
//  login
//
//  Created by Oğulcan on 20/05/2018.
//  Copyright © 2018 ogulcan. All rights reserved.
//

import Foundation
import UIKit

enum AppStoryboard: String {
    
    //case Login = "Login"
    case GalleryDoor = "GalleryDoor"
    case Main = "Main"
    case Vitrini = "Vitrini"
    case ViewrCanViewcontroller = "ViewrCanViewcontroller"
     
    var instance: UIStoryboard {
        print("Instantiating??????")
        return UIStoryboard(name: self.rawValue, bundle: Bundle.main)
    }
    
    func viewController<T : UIViewController>(viewControllerClass: T.Type, function: String = #function, line: Int = #line, file: String = #file) -> T {
        let storyboardID = (viewControllerClass as UIViewController.Type).storyboardID
        
        print(">>>>>>>>>>>>> StoryBoardID", storyboardID)
        
        guard let scene = instance.instantiateViewController(withIdentifier: storyboardID) as? T else {
            fatalError("ViewController with identifier \(storyboardID), not found in \(self.rawValue) Storyboard.\nFile : \(file) \nLine Number : \(line) \nFunction : \(function)")
        }
        
        return scene
    }
}
