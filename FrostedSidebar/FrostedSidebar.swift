//
//  FrostedSidebar.swift
//  CustomStuff
//
//  Created by Evan Dekhayser on 7/9/14.
//  Copyright (c) 2014 Evan Dekhayser. All rights reserved.
//

import UIKit
import QuartzCore

public protocol FrostedSidebarDelegate{
    func sidebar(sidebar: FrostedSidebar, willShowOnScreenAnimated animated: Bool)
    func sidebar(sidebar: FrostedSidebar, didShowOnScreenAnimated animated: Bool)
    func sidebar(sidebar: FrostedSidebar, willDismissFromScreenAnimated animated: Bool)
    func sidebar(sidebar: FrostedSidebar, didDismissFromScreenAnimated animated: Bool)
    func sidebar(sidebar: FrostedSidebar, didTapItemAtIndex index: Int)
    func sidebar(sidebar: FrostedSidebar, didEnable calloutEnabled: Bool, calloutAtIndex index: Int)
}

var sharedSidebar: FrostedSidebar?

public class FrostedSidebar: UIViewController {
    
    //MARK: Public Properties
    
    public var width:                   CGFloat                     = 144.0
    public var showFromRight:           Bool                        = false
    public var animationDuration:       CGFloat                     = 0.25
    public var calloutSize:             CGSize                      = CGSize(width: 48.0, height: 48.0)
    public var itemSize:                CGSize                      = CGSize(width: 72.0, height: 72.0)
    public var tintColor:               UIColor                     = UIColor.whiteColor()
    public var calloutBackgroundColor:  UIColor                     = UIColor(red: 123/255, green: 192/255, blue: 91/255, alpha: 1)
    public var borderWidth:             CGFloat                     = 4
    public var delegate:                FrostedSidebarDelegate?     = nil
    public var actionForIndex:         [Int : ()->()]              = [:]
    public var adjustForNavigationBar:  Bool                        = false
    public var selectedIndices:        NSMutableIndexSet           = NSMutableIndexSet()
    //Only one of these properties can be used at a time. If one is true, the other automatically is false
    public var isSingleSelect:          Bool                        = false{
        didSet{
            if isSingleSelect{ calloutsAlwaysSelected = false }
        }
    }
    public var calloutsAlwaysSelected:  Bool                        = false{
        didSet{
            if calloutsAlwaysSelected{
                isSingleSelect = false
                selectedIndices = NSMutableIndexSet(indexesInRange: NSRange(location: 0,length: images.count) )
            }
        }
    }
    public var isShowing: Bool = false
    
    //MARK: Private Properties
    
    private var contentView:            UIScrollView                = UIScrollView()
    private var blurView:               UIVisualEffectView          = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
    private var dimView:                UIView                      = UIView()
    private var tapGesture:             UITapGestureRecognizer?     = nil
    private var images:                 [UIImage]                   = []
    private var borderColors:           [UIColor]?                  = nil
    private var names:                  [String]?                  = nil

    private var calloutViews:              [CalloutItem]               = []
    
    //MARK: Public Methods
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public init(iconImages: [UIImage], colors: [UIColor]?, itemNames: [String]?, selectedItemIndices: NSIndexSet?){
        contentView.alwaysBounceHorizontal = false
        contentView.alwaysBounceVertical = true
        contentView.bounces = true
        contentView.clipsToBounds = false
        contentView.showsHorizontalScrollIndicator = false
        contentView.showsVerticalScrollIndicator = false
        if colors != nil{
            assert(iconImages.count == colors!.count, "If callout color are supplied, the calloutImages and colors arrays must be of the same size.")
        }
        
        selectedIndices = selectedItemIndices != nil ? NSMutableIndexSet(indexSet: selectedItemIndices!) : NSMutableIndexSet()
        borderColors = colors
        images = iconImages
        names = itemNames
        
        for (index, image) in images.enumerate(){
            let callout = CalloutItem(index: index)
            callout.clipsToBounds = true
            callout.imageView.image = image
            callout.labelView.text = names![index]
            callout.labelView.textAlignment = NSTextAlignment.Center
            callout.labelView.sizeToFit()
            callout.labelView.textColor = UIColor.whiteColor()
            callout.labelView.font = UIFont.systemFontOfSize(12)
            
            contentView.addSubview(callout)
            calloutViews += [callout]
            if borderColors != nil{
                if selectedIndices.containsIndex(index){
                    let color = borderColors![index]
                    callout.imageContainerView.layer.borderColor = color.CGColor
                }
            } else{
                callout.imageContainerView.layer.borderColor = UIColor.clearColor().CGColor
            }
            
        }
        
        super.init(nibName: nil, bundle: nil)
        
    }
    
    public override func loadView() {
        super.loadView()
        view.backgroundColor = UIColor.clearColor()
        view.addSubview(dimView)
        view.addSubview(blurView)
        view.addSubview(contentView)
        tapGesture = UITapGestureRecognizer(target: self, action: "handleTap:")
        view.addGestureRecognizer(tapGesture!)
    }
    
    public override func shouldAutorotate() -> Bool {
        return true
    }
    
//    public override func supportedInterfaceOrientations() -> Int {
//        return Int(UIInterfaceOrientationMask.All.rawValue)
//    }
    
    public override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        if isViewLoaded(){
            dismissAnimated(false, completion: nil)
        }
    }
    
    public func showInViewController(viewController: UIViewController, animated: Bool){
        if(isShowing){
            
            dismissAnimated(true, completion: nil)
            return
        }
       layoutItems()
        if let bar = sharedSidebar{
            bar.dismissAnimated(false, completion: nil)
        }
        
        delegate?.sidebar(self, willShowOnScreenAnimated: animated)
        
        sharedSidebar = self
        
        addToParentViewController(viewController, callingAppearanceMethods: true)
        view.frame = viewController.view.bounds
        
        dimView.backgroundColor = UIColor.blackColor()
        dimView.alpha = 0
        dimView.frame = view.bounds
        
        let parentWidth = view.bounds.size.width
        var contentFrame = view.bounds
        contentFrame.origin.x = showFromRight ? parentWidth : -width
        contentFrame.size.width = width
        contentView.frame = contentFrame
        contentView.contentOffset = CGPoint(x: 0, y: 0)
        layoutItems()
        
        var blurFrame = CGRect(x: showFromRight ? view.bounds.size.width : 0, y: 0, width: 0, height: view.bounds.size.height)
        blurView.frame = blurFrame
        blurView.contentMode = showFromRight ? UIViewContentMode.TopRight : UIViewContentMode.TopLeft
        blurView.clipsToBounds = true
        view.insertSubview(blurView, belowSubview: contentView)
        
        contentFrame.origin.x = showFromRight ? parentWidth - width : 0
        blurFrame.origin.x = contentFrame.origin.x
        blurFrame.size.width = width
        
        let animations: () -> () = {
            self.contentView.frame = contentFrame
            self.blurView.frame = blurFrame
            self.dimView.alpha = 0.25
        }
        let completion: (Bool) -> Void = { finished in
            if finished{
                self.delegate?.sidebar(self, didShowOnScreenAnimated: animated)
            }
        }
        
        if animated{
            UIView.animateWithDuration(NSTimeInterval(animationDuration), delay: 0, options: UIViewAnimationOptions.CurveLinear, animations: animations, completion: completion)
        } else{
            animations()
            completion(true)
        }
        
        for (index, callout) in calloutViews.enumerate(){
            callout.imageContainerView.layer.transform = CATransform3DMakeScale(0.3, 0.3, 1)
            callout.imageContainerView.alpha = 0
            //callout.imageContainerView.backgroundColor = calloutBackgroundColor
            callout.originalBackgroundColor = calloutBackgroundColor
            callout.imageContainerView.layer.borderWidth = borderWidth
            animateSpringWithView(callout, idx: index, initDelay: animationDuration)
        }
        isShowing = true

    }
    
    public func dismissAnimated(animated: Bool, completion: (() -> Void)?){
        let completionBlock: (Bool) -> Void = {finished in
            self.removeFromParentViewControllerCallingAppearanceMethods(true)
            self.delegate?.sidebar(self, didDismissFromScreenAnimated: true)
            self.layoutItems()
            if completion != nil{
                completion!()
            }
        }
        delegate?.sidebar(self, willDismissFromScreenAnimated: animated)
        if animated{
            let parentWidth = view.bounds.size.width
            var contentFrame = contentView.frame
            contentFrame.origin.x = showFromRight ? parentWidth : -width
            var blurFrame = blurView.frame
            blurFrame.origin.x = showFromRight ? parentWidth : 0
            blurFrame.size.width = 0
            UIView.animateWithDuration(NSTimeInterval(animationDuration), delay: 0, options: UIViewAnimationOptions.BeginFromCurrentState, animations: {
                self.contentView.frame = contentFrame
                self.blurView.frame = blurFrame
                self.dimView.alpha = 0
                }, completion: completionBlock)
        } else{
            completionBlock(true)
        }
        isShowing = false

    }
    
    public func selectItemAtIndex(index: Int){
        let didEnable = !selectedIndices.containsIndex(index)
        if borderColors != nil{
            let stroke = borderColors![index]
            let callout = calloutViews[index]
            if didEnable{
                if isSingleSelect{
                    selectedIndices.removeAllIndexes()
                    for (_, callout) in calloutViews.enumerate(){
                        callout.imageContainerView.layer.borderColor = UIColor.clearColor().CGColor
                    }
                }
                callout.imageContainerView.layer.borderColor = stroke.CGColor
                
                let borderAnimation = CABasicAnimation(keyPath: "borderColor")
                borderAnimation.fromValue = UIColor.clearColor().CGColor
                borderAnimation.toValue = stroke.CGColor
                borderAnimation.duration = 0.5
                callout.imageContainerView.layer.addAnimation(borderAnimation, forKey: nil)
                selectedIndices.addIndex(index)
                
            } else{
                if !isSingleSelect{
                    if !calloutsAlwaysSelected{
                        callout.imageContainerView.layer.borderColor = UIColor.clearColor().CGColor
                        selectedIndices.removeIndex(index)
                    }
                }
            }
            let pathFrame = CGRect(x: -CGRectGetMidX(callout.imageContainerView.bounds), y: -CGRectGetMidY(callout.imageContainerView.bounds), width: callout.imageContainerView.bounds.size.width, height: callout.imageContainerView.bounds.size.height)
            let path = UIBezierPath(roundedRect: pathFrame, cornerRadius: callout.imageContainerView.layer.cornerRadius)
            let shapePosition = view.convertPoint(callout.center, fromView: contentView)
            let circleShape = CAShapeLayer()
            circleShape.path = path.CGPath
            circleShape.position = shapePosition
            circleShape.fillColor = UIColor.clearColor().CGColor
            circleShape.opacity = 0
            circleShape.strokeColor = stroke.CGColor
            circleShape.lineWidth = borderWidth
            view.layer.addSublayer(circleShape)
            
            let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
            scaleAnimation.fromValue = NSValue(CATransform3D: CATransform3DIdentity)
            scaleAnimation.toValue = NSValue(CATransform3D: CATransform3DMakeScale(2.5, 2.5, 1))
            let alphaAnimation = CABasicAnimation(keyPath: "opacity")
            alphaAnimation.fromValue = 1
            alphaAnimation.toValue = 0
            let animation = CAAnimationGroup()
            animation.animations = [scaleAnimation, alphaAnimation]
            animation.duration = 0.5
            animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
            circleShape.addAnimation(animation, forKey: nil)
        }
        if let action = actionForIndex[index]{
            action()
        }
        delegate?.sidebar(self, didTapItemAtIndex: index)
        delegate?.sidebar(self, didEnable: didEnable, calloutAtIndex: index)
    }
    
    //MARK: Private Classes
    
    private class CalloutItem: UIView{
        var imageView:              UIImageView                 = UIImageView()
        var labelView:              UILabel                     = UILabel()
        var imageContainerView:     UIView                      = UIView()
        var calloutIndex:           Int
        var originalBackgroundColor:UIColor? {
            didSet{
                imageContainerView.backgroundColor = originalBackgroundColor
            }
        }
        
        required init?(coder aDecoder: NSCoder) {
            self.calloutIndex = 0
            super.init(coder: aDecoder)
        }
        
        init(index: Int){
            imageView.backgroundColor = UIColor.clearColor()
            imageView.contentMode = UIViewContentMode.ScaleAspectFit
            calloutIndex = index
            super.init(frame: CGRect(x: 0, y: 0, width: 48, height: 48))
            addSubview(imageContainerView)
            addSubview(imageView)
            addSubview(labelView)
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            let insetX: CGFloat = bounds.size.width/2
            let insetY: CGFloat = bounds.size.width/2.5
            
            imageView.frame = CGRect(x: 0, y: 0, width: insetX, height: insetY)
            imageView.center = CGPoint(x: insetX, y: insetY)
    
            imageContainerView.frame = CGRect(x: 0, y: 0, width: 48, height: 48)
            imageContainerView.center = CGPoint(x: insetX, y: insetY)
            
        }
        
        func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
            //super.touchesBegan(touches, withEvent: event)
            
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            let darkenFactor: CGFloat = 0.3
            var darkerColor: UIColor
            if originalBackgroundColor != nil && originalBackgroundColor!.getRed(&r, green: &g, blue: &b, alpha: &a){
                darkerColor = UIColor(red: max(r - darkenFactor, 0), green: max(g - darkenFactor, 0), blue: max(b - darkenFactor, 0), alpha: a)
            } else if originalBackgroundColor != nil && originalBackgroundColor!.getWhite(&r, alpha: &a){
                darkerColor = UIColor(white: max(r - darkenFactor, 0), alpha: a)
            } else{
                darkerColor = UIColor.clearColor()
                assert(false, "Item color should be RBG of White/Alpha in order to darken the button")
            }
            backgroundColor = darkerColor
        }
        
        func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
           // super.touchesEnded(touches, withEvent: event)
            backgroundColor = originalBackgroundColor
        }
        
        func touchesCancelled(touches: Set<NSObject>, withEvent event: UIEvent!) {
           // super.touchesCancelled(touches, withEvent: event)
            backgroundColor = originalBackgroundColor
        }
        
    }
    
    //MARK: Private Methods
    
    private func animateSpringWithView(view: CalloutItem, idx: Int, initDelay: CGFloat){
        let delay: NSTimeInterval = NSTimeInterval(initDelay) + NSTimeInterval(idx) * 0.1
        UIView.animateWithDuration(0.5,
            delay: delay,
            usingSpringWithDamping: 10.0,
            initialSpringVelocity: 50.0,
            options: UIViewAnimationOptions.BeginFromCurrentState,
            animations: {
                view.imageContainerView.layer.transform = CATransform3DIdentity
                view.imageContainerView.alpha = 1
            },
            completion: nil)
    }
    
    @objc private func handleTap(recognizer: UITapGestureRecognizer){
        let location = recognizer.locationInView(view)
        if !CGRectContainsPoint(contentView.frame, location){
            dismissAnimated(true, completion: nil)
        } else{
            let tapIndex = indexOfTap(recognizer.locationInView(contentView))
            if tapIndex != nil{
                selectItemAtIndex(tapIndex!)
            }
        }
    }
    
    private func layoutSubviews(){
        let x = showFromRight ? parentViewController!.view.bounds.size.width - width : 0
        contentView.frame = CGRect(x: x, y: 0, width: width, height: parentViewController!.view.bounds.size.height)
        blurView.frame = contentView.frame
        layoutItems()
    }
    
    private func layoutItems(){
        let leftPadding: CGFloat = (width - itemSize.width) / 2
        let topPadding: CGFloat = 6
        for (index, callout) in calloutViews.enumerate(){
            let idx: CGFloat = adjustForNavigationBar ? CGFloat(index) + 1 : CGFloat(index)
            
            let calloutSize:  CGSize  = CGSize(width: 48.0, height: 48.0)
            
            let frame = CGRect(x: leftPadding, y: topPadding*idx + itemSize.height*idx + topPadding, width:itemSize.width, height: itemSize.height)
            
            let cframe = CGRect(x: leftPadding, y: topPadding*idx + calloutSize.height*idx + topPadding, width:calloutSize.width, height: calloutSize.height)

            callout.frame = frame
            
            callout.backgroundColor = UIColor.clearColor()

            callout.imageContainerView.layer.cornerRadius = cframe.size.width / 2
            callout.imageContainerView.layer.borderColor = UIColor.clearColor().CGColor
            callout.imageContainerView.backgroundColor = UIColor.clearColor()
            callout.imageContainerView.frame = cframe
            callout.labelView.frame = CGRect(x: 0, y:56, width:72, height: 16)

            if selectedIndices.containsIndex(index){
                if borderColors != nil{
                    callout.layer.borderColor = borderColors![index].CGColor
                }
            }
            
        }
//        let calloutCount = CGFloat(calloutViews.count)
//        contentView.contentSize = CGSizeMake(0, calloutCount * (calloutSize.height + topPadding) + topPadding)
//        if adjustForNavigationBar{
//        contentView.contentSize = CGSizeMake(0, (calloutCount + 0.5) * (calloutSize.height + topPadding) + topPadding)
//        } else {
//                contentView.contentSize = CGSizeMake(0, calloutCount * (calloutSize.height + topPadding) + topPadding)
//        }
        contentView.contentSize = CGSizeMake(0,700.0)
        
    }
    
    private func indexOfTap(location: CGPoint) -> Int? {
        var index: Int?
        for (idx, callout) in calloutViews.enumerate(){
            if CGRectContainsPoint(callout.frame, location){
                index = idx
                break
            }
        }
        return index
    }
    
    private func addToParentViewController(viewController: UIViewController, callingAppearanceMethods: Bool){
        if (parentViewController != nil){
            removeFromParentViewControllerCallingAppearanceMethods(callingAppearanceMethods)
        }
        if callingAppearanceMethods{
            beginAppearanceTransition(true, animated: false)
        }
        viewController.addChildViewController(self)
        viewController.view.addSubview(self.view)
        didMoveToParentViewController(self)
        if callingAppearanceMethods{
            endAppearanceTransition()
        }
    }
    
    private func removeFromParentViewControllerCallingAppearanceMethods(callAppearanceMethods: Bool){
        
        if callAppearanceMethods{
            beginAppearanceTransition(false, animated: false)
        }
        willMoveToParentViewController(nil)
        view.removeFromSuperview()
        removeFromParentViewController()
        if callAppearanceMethods{
            endAppearanceTransition()
        }
    }
}