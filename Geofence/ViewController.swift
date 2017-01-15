//
//  ViewController.swift
//  Geofence
//
//  Created by USER on 2016/10/13.
//  Copyright © 2016年 USER. All rights reserved.
//

import UIKit
import MapKit

let FENCE_1: Double = 100
let FENCE_2: Double = 500
let FENCE_3: Double = 1000


/*
 *
 */
class CenterAnnotation : NSObject, MKAnnotation {

    var coordinate: CLLocationCoordinate2D
    
    init(coord:CLLocationCoordinate2D) {
        self.coordinate = coord
    }
    
}

class CenterAnnotationView: MKAnnotationView {

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
//        if nil != self {
            let image = UIImage(named: "target")
            self.frame = CGRect(x:self.frame.origin.x, y:self.frame.origin.y, width:(image?.size.width)!, height:(image?.size.height)!)
            self.image = image
//        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var fenceSwitch: UISwitch!
    
    var didLoadData: Bool = true
    var locationManager: CLLocationManager!
    var showingWebPage: Bool = false
    var webVC: WebViewController!
    var webMajorNumber: NSNumber = 0.0
    var webMinorNumber: NSNumber = 0.0
    
    var uuid: NSUUID?
    
    var centerLocation: CLLocationCoordinate2D?
    var centerAnnotation: CenterAnnotation?
    var regionNearby:   CLCircularRegion?
    var regionBlock:    CLCircularRegion?
    var regionTown:     CLCircularRegion?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // 以前に設定したジオフェンスを読み込む
        didLoadData = false
        self.loadData()
        
        showingWebPage = false
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        
        if locationManager.responds(to: #selector(CLLocationManager.requestAlwaysAuthorization)) {
            // iOS バージョンが 8 以上で、requestAlwaysAuthorization メソッドが
            // 利用できる場合
            
            // 位置情報測位の許可を求めるメッセージを表示する
            // ジオフェンスをする場合は、常時位置情報計測に設定する。2016−12−31
            // 常時計測にしないとデリゲート関数が出てこない！
            locationManager.requestAlwaysAuthorization()
            //        locationManager.requestWhenInUseAuthorization()
        } else {
            // iOS バージョンが 8 未満で、requestAlwaysAuthorization メソッドが
            // 利用できない場合
            
            // 測位を開始する
            locationManager.startUpdatingLocation()
        }
        
        // ビーコンの初期化
//        uuid = NSUUID(uuidString: "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0")!
        
    }

    override func viewDidAppear(_ animated: Bool) {
        if didLoadData {
            let region: MKCoordinateRegion  = MKCoordinateRegionMakeWithDistance(centerLocation!, (FENCE_3 * 3.0), (FENCE_3 * 3.0))
            mapView.setRegion(region, animated: true)
            
            self.setGeofenceAt(centerLocation!)
            fenceSwitch.isOn = true
            self.monitoring(flag: true)
        }else{
            let region: MKCoordinateRegion  = MKCoordinateRegionMakeWithDistance(mapView.userLocation.location!.coordinate, (FENCE_3*3.0), (FENCE_3*3.0))
            mapView.setRegion(region, animated: true)
            fenceSwitch.isOn = false
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

//  GeoFence job
    
    func setGeofenceAt(_ geofenceCenter: CLLocationCoordinate2D) {

        mapView.removeOverlays(mapView.overlays)
    
        centerLocation = geofenceCenter
    
        // マップに円を描く
        let fenceRange1 = MKCircle(center: centerLocation!, radius: FENCE_1)
        let fenceRange2 = MKCircle(center: centerLocation!, radius: FENCE_2)
        let fenceRange3 = MKCircle(center: centerLocation!, radius: FENCE_3)
    
        self.mapView.add(fenceRange1, level:MKOverlayLevel.aboveRoads)
        self.mapView.add(fenceRange2, level:MKOverlayLevel.aboveRoads)
        self.mapView.add(fenceRange3, level:MKOverlayLevel.aboveRoads)

        // ジオフェンスを設定する
        regionNearby = CLCircularRegion(center: fenceRange1.coordinate, radius: fenceRange1.radius, identifier: "nearby")
        regionNearby?.notifyOnEntry = true
        regionNearby?.notifyOnExit  = true
        regionBlock = CLCircularRegion(center: fenceRange2.coordinate, radius: fenceRange2.radius, identifier: "nextBlock")
        regionBlock?.notifyOnEntry = true
        regionBlock?.notifyOnExit  = true
        regionTown = CLCircularRegion(center: fenceRange3.coordinate, radius: fenceRange3.radius, identifier: "nextTown")
        regionTown?.notifyOnEntry = true
        regionTown?.notifyOnExit  = true
    }
    
    func monitoring(flag:Bool) {

        if flag == true {
            locationManager.requestState(for: regionNearby!)
    
            locationManager.startMonitoring(for: regionNearby!)
            locationManager.startMonitoring(for: regionBlock!)
            locationManager.startMonitoring(for: regionTown!)
        }
        else {
            let regions: Set<CLRegion> = locationManager.monitoredRegions
            for region:CLRegion in regions {
                locationManager.stopMonitoring(for: region)
            }
        }

    }


// - Location Job
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.authorizedAlways || status == CLAuthorizationStatus.authorizedWhenInUse {
            // 位置情報測位の許可状態が「常に許可」または「使用中のみ」の場合、
            // 測位を開始する（iOS バージョンが 8 以上の場合のみ該当する）
            // ※iOS8 以上の場合、位置情報測位が許可されていない状態で
            // 　startUpdatingLocation メソッドを呼び出しても、何も行われない。
            locationManager.startUpdatingLocation()
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        for loc: CLLocation in locations {
            
            print(String(format:"latitude %f",loc.coordinate.latitude))
            print(String(format:"longitude %f",loc.coordinate.longitude))
            
            let LocSelf: CLLocationCoordinate2D = CLLocationCoordinate2DMake(loc.coordinate.latitude, loc.coordinate.longitude)
            let selfRange1: MKCircle = MKCircle(center:LocSelf, radius:FENCE_1)
            self.mapView.add(selfRange1, level:MKOverlayLevel.aboveRoads)
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        let cr: CLCircularRegion = region as! CLCircularRegion
        print(String(format:"Monitor region with radious %f", cr.radius))
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("%@",error)
    }
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        
        // ????
        if region.identifier == regionNearby?.identifier {
            if state == CLRegionState.inside {
//                locationManager.startRangingBeacons(in: beaconRegion)
                print("startRangingBeaconsInRegion");
            }
            if state == CLRegionState.outside {
//                locationManager.stopRangingBeacons(in: beaconRegion)
                print("stopRangingBeaconsInRegion");
            }
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        
        print("Enter region")
        
        var alertStr: String?
        
        if region.identifier == "nextTown"  {
            alertStr = String(format:"ジオフェンス%.0fm内に入りました", FENCE_3)
            openWebPage(major: 5, minor: 6)
            print("nextTown : Inside")
        }
        if region.identifier == "nextBlock" {
            alertStr = String(format:"ジオフェンス%.0fm内に入りました", FENCE_2)
            openWebPage(major: 5, minor: 5)
            print("nextBlock : Inside")
        }
        if region.identifier == "nearby" {
            alertStr = String(format:"ジオフェンス%.0fm内に入りました", FENCE_1)
            openWebPage(major: 5, minor: 4)
            print("nearby : Inside")
        }
/*
swift3.0 でUILocalNotificationは非推奨になりました。ここの書き換えは今後のお楽しみ
        if (alertStr?.characters.count)! > 0 {
            let notification: UILocalNotification = UILocalNotification( alloc] init];
            notification.alertBody = alertStr;
            notification.soundName = UILocalNotificationDefaultSoundName;
            [[UIApplication sharedApplication] cancelAllLocalNotifications];
            [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
        }
 */
    }
    
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        
        print("Exit region")
        
        var alertStr: String?
        
        if region.identifier == "nearby" {
            alertStr = String(format:"ジオフェンス%.0fmから外に出ました", FENCE_1)
            openWebPage(major: 5, minor: 1)
            print("nearby : Outside")
        }
        if region.identifier == "nextBlock" {
            alertStr = String(format:"ジオフェンス%.0fmから外に出ました", FENCE_2)
            openWebPage(major: 5, minor: 2)
            print("nextBlock : Outside")
        }
        if region.identifier == "nextTown" {
            alertStr = String(format:"ジオフェンス%.0fmから外に出ました", FENCE_3)
            openWebPage(major: 5, minor: 3)
            print("nextTown : Outside")
        }
/*
        if([alertStr length] > 0) {
            UILocalNotification *notification = [[UILocalNotification alloc] init];
            notification.alertBody = alertStr;
            notification.soundName = UILocalNotificationDefaultSoundName;
            [[UIApplication sharedApplication] cancelAllLocalNotifications];
            [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
        }
 */
    }

    
// - Map job
    
    // mapViewにaddした際に呼ばれるデリゲート関数
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {

        let renderer = MKCircleRenderer(overlay: overlay)
        
        renderer.strokeColor = UIColor.red
        renderer.lineWidth = 1.0
        renderer.alpha = 0.2
        renderer.fillColor = UIColor.red
        return renderer;

    }
    
    /*
     *  CenterAnnotetionクラスで定義したマーカーが表示される直前に呼ばれるメソッドでアノテーションビューをしていする為に機能する
     */
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {

        if annotation is MKUserLocation {
            return nil
        }
        
        if annotation is CenterAnnotation {
            var annotationView: MKAnnotationView? = self.mapView.dequeueReusableAnnotationView(withIdentifier: "CenterAnnotation")
            if annotationView != nil {
                annotationView!.annotation = annotation
            }
            else{
                annotationView = MKAnnotationView(annotation:annotation, reuseIdentifier:"CenterAnnotation")
            }
            annotationView!.image = UIImage(named:"target")
            return annotationView
        }
        
        return nil
    }
    
    /*
     *
     *
     */
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        if centerAnnotation != nil {
            self.mapView.removeAnnotation(centerAnnotation!)
        }
    }
    
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if centerAnnotation != nil {
            centerAnnotation?.coordinate = self.mapView.region.center
        }
        else {
            centerAnnotation = CenterAnnotation(coord: self.mapView.region.center)
        }
        
        self.mapView.addAnnotation(centerAnnotation!)

        print(String(format:"%f,%f", self.mapView.region.center.latitude, self.mapView.region.center.longitude))
    }
  
    
// - Web job
    
    func openWebPage(major majorNumber: NSNumber, minor minorNumber: NSNumber) {
        if showingWebPage == false {
            showingWebPage = true
            webMajorNumber = majorNumber
            webMinorNumber = minorNumber
            performSegue(withIdentifier: "showWebPage", sender: self)
            print("Show web page of %02d-%02d", majorNumber.intValue, minorNumber.intValue)
        }
        else {
            webVC.loadWebPage(major: majorNumber, minor: minorNumber)
        }
        
        Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(closeWebPage), userInfo: nil, repeats: false)
    }
    
    
    func closeWebPage() {
        if showingWebPage == true {
            dismiss(animated: true, completion: nil)
            showingWebPage = false
            print("Hide web page")
        }
    }
    

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "showWebPage" {
            let nextViewController = segue.destination as! WebViewController
            webVC = nextViewController
            nextViewController.majorNumber = webMajorNumber
            nextViewController.minorNumber = webMinorNumber
        }
        
    }
    
    /*
     *  Save/Load data
     */
    func saveData() {
        
        let elatitude = NSNumber(value: centerLocation!.latitude)
        let elongitude = NSNumber(value: centerLocation!.longitude)
        
        let dict: Dictionary<String, NSNumber> = ["latitude": elatitude, "longitude": elongitude]
        let defaults = UserDefaults.standard
        defaults.set(dict, forKey: "GeofenceData")
    }
    
    func loadData() {
        let defaults = UserDefaults.standard
        if let dict = defaults.dictionary(forKey: "GeofenceData") {
            didLoadData = true
            let slatitude = dict["latitude"] as! NSNumber
            let slongitude = dict["longitude"] as! NSNumber
            centerLocation = CLLocationCoordinate2DMake(slatitude as CLLocationDegrees, slongitude as CLLocationDegrees)
        }else{
            didLoadData = true
            centerLocation = CLLocationCoordinate2DMake(35.736424, 139.605853)
        }
    }
    
    /*
     *  User Action
     */

    @IBAction func fenceSwitchValueChanged(_ sender: AnyObject) {
        let sw = sender as! UISwitch
        self.monitoring(flag: sw.isOn)
    }

    @IBAction func fenceCenterButtonPushed(_ sender: AnyObject) {
        self.setGeofenceAt(self.mapView.region.center)
        self.saveData()
        
        if fenceSwitch.isOn {
            self.monitoring(flag: false)
            self.monitoring(flag: true)
        }
    }
}

