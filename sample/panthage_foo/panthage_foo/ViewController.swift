//
//  ViewController.swift
//  panthage_foo
//
//  Created by Zhu Delun on 2019/4/12.
//  Copyright © 2019 Gamebable. All rights reserved.
//

import UIKit
import panthage_base
import panthage_libA
import panthage_libB

class ViewController: UIViewController {
    let base = BaseHelper()
    let libA = FooHelper()
    let libB = FooUtils()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        base.sayHello()
        libA.sayHello()
        libB.sayHello()
    }
}

