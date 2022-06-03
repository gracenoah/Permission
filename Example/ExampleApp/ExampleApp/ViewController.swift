//
//  ViewController.swift
//  ExampleApp
//

import UIKit

import Permission

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let permission: Permission = .camera

        print(permission.status) // .notDetermined

        permission.request { status in
            switch status {
            case .authorized:    print("authorized")
            case .denied:        print("denied")
            case .disabled:      print("disabled")
            case .notDetermined: print("not determined")
            }
        }
    }

}
