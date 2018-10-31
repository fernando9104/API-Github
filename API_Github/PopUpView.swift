//
//  PopUpView.swift
//  API_Github
//
//  Created by Developer02 on 31/10/18.
//  Copyright © 2018 Developer02. All rights reserved.
//

import UIKit

class PopUpView: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    // Funcion que eschucha el evento click del boton close
    @IBAction func closeEvent(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}
