//
//  ChatViewController.swift
//  ChatBot
//
//  Created by Alexander Danilyak on 04/03/2017.
//  Copyright © 2017 Alexander Danilyak. All rights reserved.
//

import UIKit
import Typist
import PubNub
import SwiftyJSON

protocol ChatVCProtocol {
    func newIncomingMessage(at index: Int)
}

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, PNObjectEventListener, ChatVCProtocol {
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var newMessageContainer: UIView!
    @IBOutlet weak var newMessageTextView: UITextView!
    
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var newMessageContainerToBottom: NSLayoutConstraint!
    
    @IBOutlet weak var helpButton: UIBarButtonItem!
    
    var chat: Chat?
    
    var categoriesTips: [Category]? {
        didSet {
            helpButton.isEnabled = categoriesTips != nil
        }
    }
    
    let keyboard = Typist()
    
    var isLastSending: Bool = false
    
    // -----------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        chat?.delegate = self
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44.0
        
        //UIHelper.createGradientOnView(view: sendButton)
        
        newMessageTextView.textContainerInset = UIEdgeInsetsMake(14.0, 15.0, 14.0, 15.0)
        newMessageTextView.delegate = self
        newMessageTextView.tintColor = UIHelper.pinkColor
        
        configureKeyboard()
        
        API.getTips(chatId: chat!.chatId, completion: gotTipsByCategories)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.layoutIfNeeded()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.contentInset = UIEdgeInsetsMake(6.0,
                                                  0.0,
                                                  newMessageContainer.bounds.size.height + 6.0,
                                                  0.0)
        
        if self.chat!.messages.count != 0 {
            self.tableView.scrollToRow(at: IndexPath(row: self.chat!.messages.count - 1, section: 0),
                                       at: .bottom,
                                       animated: true)
        }
    }
    
    func configureKeyboard() {
        keyboard.on(event: .willShow) { options in
            self.tableView.contentInset = UIEdgeInsetsMake(70.0,
                                                           0.0,
                                                           options.endFrame.size.height + self.newMessageContainer.bounds.size.height + 6.0,
                                                           0.0)
            self.newMessageContainerToBottom.constant = options.endFrame.size.height
            UIView.animate(withDuration: options.animationDuration,
                           delay: 0.0,
                           options: UIViewAnimationOptions(rawValue: UInt(options.animationCurve.rawValue)),
                           animations: {
                self.view.layoutIfNeeded()
            },
                           completion: nil)
            
            self.tableView.scrollToRow(at: IndexPath(row: self.chat!.messages.count - 1, section: 0),
                                       at: .bottom,
                                       animated: true)
            
        }.on(event: .willChangeFrame) { options in
            self.tableView.contentInset = UIEdgeInsetsMake(70.0,
                                                           0.0,
                                                           options.endFrame.size.height + self.newMessageContainer.bounds.size.height + 6.0,
                                                           0.0)
            self.newMessageContainerToBottom.constant = options.endFrame.size.height
            UIView.animate(withDuration: options.animationDuration,
                           delay: 0.0,
                           options: UIViewAnimationOptions(rawValue: UInt(options.animationCurve.rawValue)),
                           animations: {
                self.view.layoutIfNeeded()
            },
                           completion: nil)
        }.on(event: .willHide) { options in
            self.tableView.contentInset = UIEdgeInsetsMake(70.0,
                                                           0.0,
                                                           self.newMessageContainer.bounds.size.height + 6.0,
                                                           0.0)
            self.newMessageContainerToBottom.constant = 0.0
            UIView.animate(withDuration: options.animationDuration,
                           delay: 0.0,
                           options: UIViewAnimationOptions(rawValue: UInt(options.animationCurve.rawValue)),
                           animations: {
                            self.view.layoutIfNeeded()
            },
                           completion: nil)
        }.start()
    }
    
    // -----------------------------------
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chat == nil ? 0 : chat!.messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let isMyMessage = chat!.messages[indexPath.row].author.id == AuthData.shared.id
        
        if !isMyMessage {
            let cell = tableView.dequeueReusableCell(withIdentifier: "chatMessageCell", for: indexPath) as! ChatMessageTableViewCell
            cell.message = chat!.messages[indexPath.row]
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "chatMyMessageCell", for: indexPath) as! ChatMyMessageTableViewCell
            cell.message = chat!.messages[indexPath.row]
            
            if isLastSending && indexPath.row == chat!.messages.count - 1 {
                cell.isSending = true
            } else {
                cell.isSending = false
            }
            
            return cell
        }
    }
    
    // -----------------------------------
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.text != "" {
            sendButton.isEnabled = true
        } else {
            sendButton.isEnabled = false
        }
    }
    
    @IBAction func onSend(_ sender: Any) {
        newMessageContainer.isUserInteractionEnabled = false
        let newMessage = Message(text: newMessageTextView.text)
        newMessageTextView.text = ""
        
        API.sendMessage(chatId: chat!.chatId, message: newMessage, completion: messageSent)
        
        chat!.messages.append(newMessage)
        tableView.beginUpdates()
        tableView.insertRows(at: [IndexPath(row: chat!.messages.count - 1, section: 0)], with: .bottom)
        tableView.endUpdates()
        let cell = tableView.cellForRow(at: IndexPath(row: self.chat!.messages.count - 1, section: 0))
        cell?.layoutSubviews()
        self.tableView.scrollToRow(at: IndexPath(row: self.chat!.messages.count - 1, section: 0),
                                   at: .bottom,
                                   animated: true)
    }
    
    @IBAction func onHelp(_ sender: Any) {
    }
    
    
    // -----------------------------------
    
    func messageSent(isSucces: Bool) -> () {
        if isSucces {
            let cell = tableView.cellForRow(at: IndexPath(row: chat!.messages.count - 1, section: 0)) as! ChatMyMessageTableViewCell
            cell.isSending = false
        } else {
            chat!.messages.removeLast()
            tableView.beginUpdates()
            tableView.deleteRows(at: [IndexPath(row: chat!.messages.count - 1, section: 0)], with: .bottom)
            tableView.endUpdates()
            let cell = tableView.cellForRow(at: IndexPath(row: self.chat!.messages.count - 1, section: 0))
            cell?.layoutSubviews()
            self.tableView.scrollToRow(at: IndexPath(row: self.chat!.messages.count - 1, section: 0),
                                       at: .bottom,
                                       animated: true)
        }
        
        newMessageContainer.isUserInteractionEnabled = true
    }
    
    // -----------------------------------
    
    func newIncomingMessage(at index: Int) {
        tableView.beginUpdates()
        tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .bottom)
        tableView.endUpdates()
        self.tableView.scrollToRow(at: IndexPath(row: self.chat!.messages.count - 1, section: 0),
                                   at: .bottom,
                                   animated: true)
    }
    
    // -----------------------------------
    
    func gotTipsByCategories(json: JSON) -> () {
        categoriesTips = []
        
        for categoryJson in json.arrayValue {
            categoriesTips?.append(Category(json: categoryJson))
        }
    }
}