//
//  TypstSourceWorkbenchViewController.swift
//  Serifian
//
//  Created by Riccardo Persello on 28/05/23.
//

import UIKit

class TypstSourceWorkbenchViewController: UIViewController {

    @IBOutlet weak var textViewWidthConstraint: NSLayoutConstraint!

    @IBAction func dividerPanned(_ sender: UIPanGestureRecognizer) {
        let translation = sender.location(in: self.view)

        textViewWidthConstraint.constant = translation.x
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
