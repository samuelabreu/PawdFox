//
//  ViewController.swift
//  PawdFox
//
//  Created by samuel.abreu on 10/01/2018.
//  Copyright © 2018 Personal Project. All rights reserved.
//

import Cocoa

struct TABS {
    static let PASSWORD: Int = 0
    static let MAINMESSAGE: Int = 1
    static let DATA: Int = 2
}

class ViewController: NSViewController {
    
    var profileIniPath = "\(NSHomeDirectory())/Library/Application Support/Firefox/"
    
    lazy var wrapper: WrapperClass = {
        return WrapperClass()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ProfileSelectorComboBox.delegate = self
        resetUi()
        startApp()
        DataTableView.delegate = self
        DataTableView.dataSource = self
    }
    
    override func viewDidAppear() {
        if let mainMenu = NSApplication.shared.mainMenu {
            if let tools = mainMenu.item(withTag: 103)?.submenu {
                if let clearClipboard = tools.item(withTag: 1031)?.submenu {
                    for item in clearClipboard.items {
                        item.state = NSControl.StateValue.off
                    }
                    let defaults = NSUserDefaultsController.shared.defaults
                    if let val = defaults.value(forKey: "clearClipboardSetting") as? Int {
                        switch val {
                        case 10:
                            clearClipboard.item(withTag: 10311)?.state = NSControl.StateValue.on
                            break
                        case 30:
                            clearClipboard.item(withTag: 10312)?.state = NSControl.StateValue.on
                            break
                        default:
                            clearClipboard.item(withTag: 10313)?.state = NSControl.StateValue.on
                        }
                    }
                }
            }
        }
        
    }
    
    override var representedObject: Any? {
        didSet {
        }
    }
    
    // MARK: Properties
    var credentials = NSArray()
    @IBOutlet weak var PasswordTextField: NSSecureTextField!
    @IBOutlet weak var SearchTextField: NSSearchField!
    @IBOutlet weak var SenhaIncorretaLabel: NSTextField!
    @IBOutlet weak var ProfileSelectorComboBox: NSComboBox!
    @IBOutlet weak var MainTabView: NSTabView!
    @IBOutlet weak var InfoMessageLabel: NSTextField!
    @IBOutlet weak var DataTableView: NSTableView!
    
    var timer = Timer()
    
    
    func openProfile(_ password: String = "") {
        let closeStatus = wrapper.closeProfile()
        if closeStatus != 0 {
            setErrorLabel("An unknown error ocurred using NSS library, please close and try again!")
            return
        }
        let index = Int32(ProfileSelectorComboBox.indexOfSelectedItem)
        let statusRead = wrapper.readLogins(index, withPassword: password)
        if statusRead == -4 {
            if password != "" {
                shake()
                SenhaIncorretaLabel.isHidden = false
            }
            askPassword()
        } else if statusRead == 0 {
            SenhaIncorretaLabel.isHidden = true
            PasswordTextField.stringValue = ""
            loadLogins()
            SearchTextField.window?.makeFirstResponder(SearchTextField)
        } else if statusRead == -2 {
            setErrorLabel("It was not possible open Firefox profile file, make sure the selected profile has at least one account saved!")
        } else {
            setErrorLabel("Sorry. Couldn't open Firefox profile.")
        }
    }
    
    @IBAction func confirmPassword(_ sender: Any) {
        openProfile(PasswordTextField.stringValue)
        
    }
    
    @IBAction func SearchAction(_ sender: Any) {
        let query = SearchTextField.stringValue
        loadLogins(query)
    }
    
    // MARK: Logic
    func startApp() {
        let statusOpen = wrapper.openIni(profileIniPath)
        if statusOpen != 0 { // Não achou o profiles.ini
            setErrorLabel("Firefox not found!")
            //TODO: Solicitar o usuário onde está o profiles.ini
        } else {
            let count = wrapper.profileSize()
            if (count == 0) {
                //TODO: Solicitar o usuário onde está o profiles.ini
                setErrorLabel("Couldn't find any Firefox profile on default path.")
            } else {
                if (count > 1) {
                    ProfileSelectorComboBox.isEnabled = true
                }
                let profiles = wrapper.profiles()
                ProfileSelectorComboBox.removeAllItems()
                for profile in profiles! {
                    ProfileSelectorComboBox.addItem(withObjectValue: profile as! NSString)
                }
                if ProfileSelectorComboBox.numberOfItems > 0 {
                    ProfileSelectorComboBox.selectItem(at: 0)
                }
            }
        }
    }
    
    func loadLogins(_ query: String? = nil) {
        MainTabView.selectTabViewItem(at: TABS.DATA)
        var finalQuery: String? = query
        if finalQuery == nil && SearchTextField.stringValue != "" {
            finalQuery = SearchTextField.stringValue
        }
        if finalQuery != nil {
            credentials = wrapper.filter(finalQuery)! as NSArray
        } else {
            credentials = wrapper.credentials()! as NSArray
        }
        SearchTextField.isEnabled = true
        DataTableView.reloadData()
    }
    
    func askPassword() {
        MainTabView.selectTabViewItem(at: TABS.PASSWORD)
        //        PasswordTextField.becomeFirstResponder()
    }
    
    func decPassword(_ row: Int) -> String {
        if credentials.count > row {
            let pwenc = (credentials[DataTableView.clickedRow] as! Credential).encryptedPassword as String
            guard let pwd = self.wrapper.decryptPassword(pwenc) else {
                resetUi()
                startApp()
                setErrorLabel("Wrong password!")
                return ""
            }
            return pwd
            //TODO: Opção pra limpar clipboard depois de alguns segundos
            //TODO: Alerta avisando que vai tirar do clipboard depois de alguns segundos
            //TODO: Limpar depois de alguns segundos
        }
        return ""
    }
    
    func copyToClipboard(_ data: String) {
        let pasteBoard = NSPasteboard.general
        pasteBoard.clearContents()
        pasteBoard.writeObjects([data as NSString])
    }
    
    @objc func clearClipboard() {
        copyToClipboard("")
    }
    
    @IBAction func VisitarSite(_ sender: Any) {
        if let checkURL = NSURL(string: (credentials[DataTableView.clickedRow] as! Credential).site as String) {
            if NSWorkspace.shared.open(checkURL as URL) {
                
            }
        }
    }
    
    @IBAction func goToSearchField(_ sender: Any?) {
        SearchTextField.window?.makeFirstResponder(SearchTextField)
    }
    
    @IBAction func CopiarEndereco(_ sender: Any) {
        copyToClipboard((credentials[DataTableView.clickedRow] as! Credential).site as String)
    }
    
    @IBAction func CopiarUsername(_ sender: Any) {
        copyToClipboard((credentials[DataTableView.clickedRow] as! Credential).username as String)
    }
    
    @IBAction func CopiarItemMenuAction(_ sender: Any) {
        let pwd = decPassword(DataTableView.clickedRow)
        copyToClipboard(pwd)
        setTimerToClearClipboard()
    }
    
    @IBAction func RevelarItemMenuAction(_ sender: Any) {
        let pwd = decPassword(DataTableView.clickedRow)
        
        let alert = NSAlert()
        alert.messageText = "Password"
        alert.informativeText = pwd
        alert.addButton(withTitle: "Close")
        alert.addButton(withTitle: "Copy")
        alert.alertStyle = NSAlert.Style.warning
        alert.beginSheetModal(for: self.view.window!, completionHandler: { [unowned self] (returnCode) -> Void in
            if returnCode == NSApplication.ModalResponse.alertSecondButtonReturn {
                self.copyToClipboard(pwd)
                self.setTimerToClearClipboard()
            }
        })
    }
    
    @IBAction func openDocument(_ sender: Any) {
        openProfileIniSelector()
    }
    
    func openProfileIniSelector() {
        let dialog = NSOpenPanel()
        
        dialog.title                   = "Choose a profiles.ini file"
        dialog.showsResizeIndicator    = true
        dialog.showsHiddenFiles        = true
        dialog.canChooseDirectories    = true
        dialog.canCreateDirectories    = false
        dialog.allowsMultipleSelection = false
        dialog.allowedFileTypes        = ["ini"]
        dialog.canChooseFiles          = false
        
        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            let result = dialog.url // Pathname of the file
            
            if (result != nil) {
                let path = result!.path
                openProfileIniPath(path)
            }
        } else {
            // User clicked on "Cancel"
            return
        }
    }
    
    func openProfileIniPath(_ path: String) {
        let closeStatus = wrapper.closeProfile()
        resetDataUi()
        if (closeStatus != 0) {
            //TODO: Tratar erro ao fechar perfil.
        } else {
            ProfileSelectorComboBox.removeAllItems()
            ProfileSelectorComboBox.isEnabled = false
            let statusOpen = wrapper.openIni(path)
            if (statusOpen == 0) {
                let count = wrapper.profileSize()
                if (count == 0) {
                    //TODO: Solicitar o usuário onde está o profiles.ini
                    setErrorLabel("Couldn't find any Firefox profile on default path.")
                } else {
                    
                    NSDocumentController.shared.noteNewRecentDocumentURL(NSURL.fileURL(withPath: path))
                    
                    
                    if (count > 1) {
                        ProfileSelectorComboBox.isEnabled = true
                    }
                    let profiles = wrapper.profiles()
                    for profile in profiles! {
                        ProfileSelectorComboBox.addItem(withObjectValue: profile as! NSString)
                    }
                    if ProfileSelectorComboBox.numberOfItems > 0 {
                        ProfileSelectorComboBox.selectItem(at: 0)
                    }
                }
            } else {
                setErrorLabel("Couldn't open profiles.ini!")
            }
        }
    }
    
    @IBAction func clearClipboardAction(_ sender: Any) {
        if let menuitem = sender as? NSMenuItem {
            if let mainMenu = NSApplication.shared.mainMenu {
                if let tools = mainMenu.item(withTag: 103)?.submenu {
                    if let clearClipboard = tools.item(withTag: 1031)?.submenu {
                        for item in clearClipboard.items {
                            item.state = NSControl.StateValue.off
                        }
                    }
                }
            }
            menuitem.state = NSControl.StateValue.on
            let defaults = NSUserDefaultsController.shared.defaults
            switch menuitem.tag {
            case 10311:
                defaults.set(10, forKey: "clearClipboardSetting")
                break
            case 10312:
                defaults.set(30, forKey: "clearClipboardSetting")
                break
            default:
                timer.invalidate()
                defaults.set(0, forKey: "clearClipboardSetting")
            }
        }
    }
    
    func setTimerToClearClipboard() {
        timer.invalidate()
        var timeToClear = 0
        let defaults = NSUserDefaultsController.shared.defaults
        if let val = defaults.value(forKey: "clearClipboardSetting") as? Int {
            timeToClear = val
        }
        if timeToClear > 0 {
            self.timer = Timer.scheduledTimer(timeInterval: TimeInterval(timeToClear), target: self, selector: #selector(self.clearClipboard), userInfo: nil, repeats: false)
        }
    }
    
    // MARK: Cosmetic
    func shake() {
        let numberOfShakes:Int = 8
        let durationOfShake:Float = 0.3
        let vigourOfShake:Float = 0.01
        
        let frame:CGRect = (self.view.window!.frame)
        let shakeAnimation = CAKeyframeAnimation()
        
        let shakePath = CGMutablePath()
        shakePath.move(to: CGPoint(x: NSMinX(frame), y: NSMinY(frame)))
        
        for _ in 1...numberOfShakes {
            shakePath.addLine(to: CGPoint(x:NSMinX(frame) - frame.size.width * CGFloat(vigourOfShake), y: NSMinY(frame)))
            shakePath.addLine(to: CGPoint(x:NSMinX(frame) + frame.size.width * CGFloat(vigourOfShake), y: NSMinY(frame)))
        }
        
        shakePath.closeSubpath()
        shakeAnimation.path = shakePath
        shakeAnimation.duration = CFTimeInterval(durationOfShake)
        self.view.window?.animations = [NSAnimatablePropertyKey(rawValue: "frameOrigin"):shakeAnimation]
        self.view.window?.animator().setFrameOrigin((self.view.window?.frame.origin)!)
    }
    
    func resetUi() {
        ProfileSelectorComboBox.isEnabled = false
        resetDataUi()
    }
    
    func resetDataUi() {
        SearchTextField.isEnabled = false
        credentials = NSArray()
        SenhaIncorretaLabel.isHidden = true
        MainTabView.selectTabViewItem(at: TABS.MAINMESSAGE)
        InfoMessageLabel.stringValue = "PawdFox show saved accounts on your Firefox Profile."
        InfoMessageLabel.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
    }
    
    func setErrorLabel(_ message: String) {
        InfoMessageLabel.stringValue = message
        InfoMessageLabel.textColor = #colorLiteral(red: 0.7764756944, green: 0, blue: 0, alpha: 1)
        MainTabView.selectTabViewItem(at: TABS.MAINMESSAGE)
    }
    
}

extension ViewController: NSComboBoxDelegate {
    func comboBoxSelectionDidChange(_ notification: Notification) {
        if ProfileSelectorComboBox.indexOfSelectedItem >= 0 {
            resetDataUi()
            openProfile()
        }
    }
}

extension ViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return credentials.count
    }
}

extension ViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var text: String = ""
        if tableColumn?.identifier.rawValue == "SiteColumn" {
            text = (credentials[row] as! Credential).site
        } else if tableColumn?.identifier.rawValue == "UsernameColumn" {
            text = (credentials[row] as! Credential).username
        }
        
        if let cell = tableView.makeView(withIdentifier: (tableColumn?.identifier)!, owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            return cell
        }
        return nil
    }
}

