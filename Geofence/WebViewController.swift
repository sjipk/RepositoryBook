//
//  WebViewController.swift
//  Geofence
//
//  Created by USER on 2016/10/13.
//  Copyright © 2016年 USER. All rights reserved.
//

import UIKit

class WebViewController: UIViewController, UIWebViewDelegate {
    
    @IBOutlet weak var webView: UIWebView!
    var majorNumber: NSNumber = 0.0
    var minorNumber: NSNumber = 0.0
/*
    - (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
    {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    // Custom initialization
    }
    return self;
    }
*/
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.loadWebPageEx()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadWebPageEx() {
        // iOS9からAppTransportSecurityを設定する　2016−12−31
        let urlString = String(format:"http://newtonworks.sakura.ne.jp/wp/LocatedItems/%02d-%02d/", self.majorNumber.intValue, self.minorNumber.intValue)
        
//        let url: NSURL = NSURL(fileURLWithPath: urlString)
        let url = NSURL(string: urlString)!
        
        let urlRequest = NSURLRequest(url: url as URL)
        self.webView.loadRequest(urlRequest as URLRequest)
    }

    func loadWebPage(major majorNumber: NSNumber, minor minorNumber: NSNumber) {
        
        if self.majorNumber.intValue != majorNumber.intValue || self.minorNumber.intValue != minorNumber.intValue {
            self.majorNumber = majorNumber
            self.minorNumber = minorNumber
            self.loadWebPageEx()
        }
    }
}
