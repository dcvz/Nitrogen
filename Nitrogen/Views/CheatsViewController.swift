//
//  CheatsViewController.swift
//  Nitrogen
//
//  Created by David Chavez on 25/03/16.
//  Copyright © 2016 Mystical. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import PureLayout

class CheatsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {

    // MARK: - Attributes

    var emulator: EmulatorCore!
    var gameTitle = ""
    var currentEditingCheat: Int?


    // MARK: - IBOutlets

    @IBOutlet weak var gameTitleLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!

    @IBOutlet weak var editView: UIView!
    @IBOutlet weak var discardButton: UIButton!
    @IBOutlet weak var cheatTitleTextField: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var cheatTextView: UITextView!
    @IBOutlet weak var editHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addButton: UIBarButtonItem!


    // MARK: - Attributes (Reactive)

    private let hankeyBag = DisposeBag()


    // MARK: - UIView Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupView()
    }


    // MARK: - Private Methods

    private func setupView() {
        gameTitleLabel.text = gameTitle
        
        closeButton.rx_tap.subscribeNext() { [weak self] in
            self?.dismissViewControllerAnimated(true, completion: nil)
        }.addDisposableTo(hankeyBag)

        saveButton.rx_tap.subscribeNext() { [weak self] in
            guard let title = self?.cheatTitleTextField.text, cheat = self?.cheatTextView.text
                where title.characters.count > 0 || cheat.characters.count > 0 else { return }

            if let editingPosition = self?.currentEditingCheat {
                self?.emulator.updateCheatWithDescription(title, code: cheat, atPosition: UInt(editingPosition))
            } else {
                self?.emulator.addCheatWithDescription(title, code: cheat)
            }

            self?.emulator.saveCheats()
            self?.currentEditingCheat = nil
            self?.hideEditor() {
                self?.tableView.reloadData()
            }
        }.addDisposableTo(hankeyBag)

        cheatTextView.rx_text.subscribeNext() { [weak self] text in
            var code = text.stringByReplacingOccurrencesOfString(" ", withString: "")
            code = code.stringByReplacingOccurrencesOfString("\n", withString: "")

            var resultString = ""
            for (i, char) in code.characters.enumerate() {
                resultString.append(char)
                if (i + 1) % 16 == 0 && i != 0 && i < code.characters.count - 1 {
                    resultString.appendContentsOf("\n")
                } else if (i + 1) % 8 == 0 && i < code.characters.count - 1 {
                    resultString.appendContentsOf(" ")
                }
            }

            resultString = resultString.uppercaseString
            if let cursorPosition = self?.cheatTextView.selectedRange {
                self?.cheatTextView.text = resultString
                dispatch_async(dispatch_get_main_queue()) {
                    self?.cheatTextView.selectedRange = NSMakeRange(cursorPosition.location + 1, 0)
                }
            }
        }.addDisposableTo(hankeyBag)

        addButton.rx_tap.subscribeNext() { [weak self] in
            self?.currentEditingCheat = nil
            self?.showEditor()
        }.addDisposableTo(hankeyBag)

        discardButton.rx_tap.subscribeNext() { [weak self] in
            self?.currentEditingCheat = nil
            self?.hideEditor()
        }.addDisposableTo(hankeyBag)
    }

    private func showEditor(description: String = "", cheat: String = "") {
        editHeightConstraint.constant = 138
        cheatTitleTextField.text = description
        cheatTextView.text = cheat
        UIView.animateWithDuration(0.3, animations: { [weak self] in
            self?.editView.alpha = 1.0
            self?.view.layoutIfNeeded()
        }, completion: nil)
    }

    private func hideEditor(completion: (() -> Void)? = nil) {
        editHeightConstraint.constant = 0
        cheatTitleTextField.text = ""
        cheatTextView.text = ""
        view.endEditing(true)
        UIView.animateWithDuration(0.3, animations: { [weak self] in
            self?.editView.alpha = 0.0
            self?.view.layoutIfNeeded()
        }, completion: { finished in
                completion?()
        })
    }


    // MARK: - UITableViewController

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Int(emulator.numberOfCheats())
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cheatCell", forIndexPath: indexPath)
        cell.textLabel?.text = emulator.cheatNameAtPosition(UInt(indexPath.item))
        cell.accessoryType = emulator.cheatEnabledAtPosition(UInt(indexPath.item)) ? .Checkmark : .None
        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        emulator.setCheatEnabled(!emulator.cheatEnabledAtPosition(UInt(indexPath.item)), atPosition: UInt(indexPath.item))
        tableView.reloadData()
    }

    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .Destructive, title: "Delete") { action, indexPath in
            self.emulator.deleteCheatAtPosition(UInt(indexPath.item))
            self.emulator.saveCheats()

            if let currentEditingPosition = self.currentEditingCheat {
                if currentEditingPosition == indexPath.item {
                    self.currentEditingCheat = nil
                    self.cheatTitleTextField.text = ""
                    self.cheatTextView.text = ""
                }
            }

            tableView.reloadData()
        }

        let edit = UITableViewRowAction(style: .Normal, title: "Edit") { (action, indexPath) in
            let description = self.emulator.cheatNameAtPosition(UInt(indexPath.item))
            let code = self.emulator.cheatCodeAtPosition(UInt(indexPath.item))
            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            self.currentEditingCheat = indexPath.item
            self.showEditor(description, cheat: code)
        }

        edit.backgroundColor = UIColor.lightGrayColor()
        
        return [delete, edit]
    }


    // MARK: - UITextFieldDelegate

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        cheatTextView.becomeFirstResponder()
        return false
    }
}
