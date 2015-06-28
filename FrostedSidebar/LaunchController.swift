//
//  LaunchController.swift
//  GlutenFree
//
//  Created by James Cicenia on 6/24/15.
//  Copyright (c) 2015 James Cicenia. All rights reserved.
//

import Foundation

class LaunchController: UIViewController {

    var sidebar: FrostedSidebar!

    
    override func viewDidLoad() {
        super.viewDidLoad()

        let burgerButton  = UIBarButtonItem(image:UIImage(named: "hamburger-icon"), style: UIBarButtonItemStyle.Plain, target: self, action: "onBurger")
        self.navigationItem.leftBarButtonItem = burgerButton

        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        
        let vc = storyboard.instantiateViewControllerWithIdentifier("NewsHome") as! NewsTableViewController
        self.navigationController?.pushViewController(vc, animated: false)
        
        
        sidebar = FrostedSidebar(iconImages: [
            UIImage(named: "fm-home")!,
            UIImage(named: "fm-shopping-list")!,
            UIImage(named: "fm-likes")!,
            UIImage(named: "fm-products")!,
            UIImage(named: "fm-stores")!,
            UIImage(named: "fm-brands")!,
            UIImage(named: "fm-faq")!,
            UIImage(named: "fm-settings")!],
            colors: [
                UIColor(red: 123/255, green: 192/255, blue: 91/255, alpha: 1),
                UIColor(red: 123/255, green: 192/255, blue: 91/255, alpha: 1),
                UIColor(red: 123/255, green: 192/255, blue: 91/255, alpha: 1),
                UIColor(red: 123/255, green: 192/255, blue: 91/255, alpha: 1),
                UIColor(red: 123/255, green: 192/255, blue: 91/255, alpha: 1),
                UIColor(red: 123/255, green: 192/255, blue: 91/255, alpha: 1),
                UIColor(red: 123/255, green: 192/255, blue: 91/255, alpha: 1),
                UIColor(red: 123/255, green: 192/255, blue: 91/255, alpha: 1)],
            itemNames: ["Home","Shopping","Like No Like", "Products","Stores","Brands","FAQ","Settings"],
            selectedItemIndices: NSIndexSet(index: 0))
        
        sidebar.isSingleSelect = true
        sidebar.actionForIndex = [
            0: {self.sidebar.dismissAnimated(true, completion: {
                let vc = storyboard.instantiateViewControllerWithIdentifier("NewsHome") as! NewsTableViewController
                self.navigationController?.pushViewController(vc, animated: false)
                
            })},
            1: {self.sidebar.dismissAnimated(true, completion: {
                let vc = storyboard.instantiateViewControllerWithIdentifier("ShoppingListTableViewController") as! ShoppingListTableViewController
                self.navigationController?.pushViewController(vc, animated: false)
                
            })},
            2: {self.sidebar.dismissAnimated(true, completion: {
                let vc = storyboard.instantiateViewControllerWithIdentifier("LikeNoLike") as! LikeNoLikeTableViewController
                self.navigationController?.pushViewController(vc, animated: false)
                
            })},
            3: {self.sidebar.dismissAnimated(true, completion: {
                let vc = storyboard.instantiateViewControllerWithIdentifier("ProductTableViewController") as! ProductTableViewController
                self.navigationController?.pushViewController(vc, animated: false)
                
            })},
            4: {self.sidebar.dismissAnimated(true, completion: {
                let vc = storyboard.instantiateViewControllerWithIdentifier("StoreTableViewController") as! StoreTableViewController
                self.navigationController?.pushViewController(vc, animated: false)
                
            })},
            5: {self.sidebar.dismissAnimated(true, completion: {
                let vc = storyboard.instantiateViewControllerWithIdentifier("BrandTableViewController") as! BrandTableViewController
                self.navigationController?.pushViewController(vc, animated: false)
                
            })},
            6: {self.sidebar.dismissAnimated(true, completion: {
                let vc = storyboard.instantiateViewControllerWithIdentifier("WebViewController") as! WebViewController
                vc.name = "AboutUs"
                self.navigationController?.pushViewController(vc, animated: false)
                
            })},
            7: {self.sidebar.dismissAnimated(true, completion: {
                let vc = storyboard.instantiateViewControllerWithIdentifier("SettingsViewController") as! SettingsViewController
                self.navigationController?.pushViewController(vc, animated: false)
                
            })},
        
        
        
        ]
        
    }
    
    func onBurger() {
        self.sidebar.showInViewController(self, animated: false)
    }
    
    
    //
    
    override func viewDidAppear(animated: Bool){
        super.viewDidAppear(false   );
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        if(((appDelegate.firstTime) != nil) && (appDelegate.firstTime == true)){
            self.displayFirstTimeAlert()
        }
    }
    
    
    func displayFirstTimeAlert(){
        
        let message = "Please go to settings and set your preferred zipcode."
        var alert = UIAlertController(title: "Welcome", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
        
    }
    

}