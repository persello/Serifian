//
//  WorkbenchViewController.swift
//  Serifian
//
//  Created by Riccardo Persello on 27/05/23.
//

import UIKit

class WorkbenchViewController: UIViewController {

    @IBAction func backButtonPressed(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    func setupTitleMenuProvider(_ url: URL) {
        self.navigationItem.titleMenuProvider = { suggestedActions in
            var children = suggestedActions
            return UIMenu(children: children)
        }

//        workbenchViewController.navigationItem.title = document.title

        self.navigationItem.documentProperties = UIDocumentProperties(url: url)
    }
}
