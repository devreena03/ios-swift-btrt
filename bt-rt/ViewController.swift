//
//  ViewController.swift
//  bt-rt
//
//  Created by Kumari, Reena on 12/26/18.
//  Copyright © 2018 Kumari, Reena. All rights reserved.
//

import UIKit
import Braintree
import Braintree.BraintreePayPal

class ViewController: UIViewController, BTAppSwitchDelegate , BTViewControllerPresentingDelegate {
  
    var braintreeClient: BTAPIClient?
    var client_token: String!
    let BASE_URL = "https://paypal-integration-sample.herokuapp.com";
    let CLIENT_TOKEN_URL = "/api/paypal/ecbt/client_token";
    
    let VAULT = "/api/paypal/ecbt/vault";
    let VAULT_WITH_PAYMENT = "/api/paypal/ecbt/vaultwithpayment";
    
    let AUTO_PAY = "/api/paypal/ecbt/autopay";
    
    @IBOutlet weak var input_token: UITextField!
    
    @IBOutlet weak var vaultwithpayment_email: UILabel!
    @IBOutlet weak var vaultwithpayment_token: UILabel!
    @IBOutlet weak var vault_email: UILabel!
    @IBOutlet weak var vault_token: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getClientToken();
    }
    
    func getClientToken(){
        
        guard let url = URL(string: BASE_URL+CLIENT_TOKEN_URL) else {return}
        
        let session = URLSession.shared;
        session.dataTask(with: url) { (data, response, error) in
            if let data = data {
                self.client_token = String(data: data, encoding: String.Encoding.utf8);
                print(self.client_token);
            }
            }.resume();
    }
    
    @IBAction func vaultWithPayment(_ sender: Any) {
        braintreeClient = BTAPIClient(authorization: client_token)
        
        let payPalDriver = BTPayPalDriver(apiClient: braintreeClient!)
        payPalDriver.appSwitchDelegate = self // Optional
        
        let request = BTPayPalRequest()
        request.billingAgreementDescription = "My iOS Testing billing agreement";
        payPalDriver.requestBillingAgreement(request) { (tokenizedPayPalAccount, error) -> Void in
            if let tokenizedPayPalAccount = tokenizedPayPalAccount {
                print("Got a nonce: \(tokenizedPayPalAccount.nonce)")
                
                let payload = ["nonce": tokenizedPayPalAccount.nonce,"amount":"1.00","currency":"USD"];
                guard let body = try? JSONSerialization.data(withJSONObject: payload, options: []) else {return}
                
                guard let url = URL(string: self.BASE_URL+self.VAULT_WITH_PAYMENT) else {return}
                
                var urlRequest = URLRequest(url: url);
                urlRequest.httpMethod = "POST";
                urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
                urlRequest.httpBody = body;
                
                let session = URLSession.shared;
                session.dataTask(with: urlRequest) { (data, response, error) in
                    if let data = data {
                        do{
                            let jsonData = try JSONSerialization.jsonObject(with: data, options: [])
                            print(jsonData);
                            if let values = jsonData as? [String: Any]{
                                let token = values["token"] as! String;
                                let payerEmail = values["payerEmail"] as! String;
                                DispatchQueue.main.async {
                                    self.vaultwithpayment_email.text = payerEmail;
                                    self.vaultwithpayment_token.text = token;
                                    self.input_token.text = token;
                                }
                            }
                        }catch {
                            print("error");
                        }
                    }
                    }.resume();
                // Send payment method nonce to your server to create a transaction
            } else if let error = error {
                // Handle error here...
            } else {
                // Buyer canceled payment approval
            }
        }
    }
    
    @IBAction func vault(_ sender: Any) {
        braintreeClient = BTAPIClient(authorization: client_token)
        
        let payPalDriver = BTPayPalDriver(apiClient: braintreeClient!)
        payPalDriver.appSwitchDelegate = self // Optional
        
        let request = BTPayPalRequest()
        request.billingAgreementDescription = "My iOS Testing billing agreement";
        payPalDriver.requestBillingAgreement(request) { (tokenizedPayPalAccount, error) -> Void in
            if let tokenizedPayPalAccount = tokenizedPayPalAccount {
                print("Got a nonce: \(tokenizedPayPalAccount.nonce)")
                
                let payload = ["nonce": tokenizedPayPalAccount.nonce];
                guard let body = try? JSONSerialization.data(withJSONObject: payload, options: []) else {return}
                
                guard let url = URL(string: self.BASE_URL+self.VAULT) else {return}
                
                var urlRequest = URLRequest(url: url);
                urlRequest.httpMethod = "POST";
                urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
                urlRequest.httpBody = body;
                
                let session = URLSession.shared;
                session.dataTask(with: urlRequest) { (data, response, error) in
                    if let data = data {
                        do{
                            let jsonData = try JSONSerialization.jsonObject(with: data, options: [])
                            print(jsonData);
                            if let values = jsonData as? [String: Any]{
                                let token = values["token"] as! String;
                                let payerEmail = values["payerEmail"] as! String;
                                DispatchQueue.main.async {
                                    self.vault_email.text = payerEmail;
                                    self.vault_token.text = token;
                                    self.input_token.text = token;
                                }
                            }
                        }catch {
                            print("error");
                        }
                    }
                    }.resume();
                // Send payment method nonce to your server to create a transaction
            } else if let error = error {
                // Handle error here...
            } else {
                // Buyer canceled payment approval
            }
        }
    }
    
    @IBAction func autopay(_ sender: Any) {
        let payload = ["amount": "1.00","currency":"USD","rt_token":input_token.text!];
        guard let body = try? JSONSerialization.data(withJSONObject: payload, options: []) else {return}
        
        guard let url = URL(string: self.BASE_URL+self.AUTO_PAY) else {return}
        
        var urlRequest = URLRequest(url: url);
        urlRequest.httpMethod = "POST";
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = body;
        
        let session = URLSession.shared;
        session.dataTask(with: urlRequest) { (data, response, error) in
            if let data = data {
                do{
                    let jsonData = try JSONSerialization.jsonObject(with: data, options: [])
                    print(jsonData);
                    if let values = jsonData as? [String: Any]{
                        let id = values["paymentId"] as! String;
                        DispatchQueue.main.async {
                            self.displayAlertMessage(msg: "Payment completed, payment Id: " + id);
                        }
                    }
                    
                }catch {
                    print("error");
                }
            }
            }.resume();
    }
    
    func displayAlertMessage(msg: String){
        let alert = UIAlertController.init(title: "Alert", message: msg, preferredStyle: .alert)
        
        let userAction = UIAlertAction.init(title: "OK", style: .destructive, handler: nil)
        alert.addAction(userAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    func paymentDriver(_ driver: Any, requestsDismissalOf viewController: UIViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    func paymentDriver(_ driver: Any, requestsPresentationOf viewController: UIViewController) {
        present(viewController, animated: true, completion: nil)
    }
    
    // MARK: - BTAppSwitchDelegate
    
    func appSwitcherWillPerformAppSwitch(_ appSwitcher: Any) {
        
    }
    
    func appSwitcher(_ appSwitcher: Any, didPerformSwitchTo target: BTAppSwitchTarget) {
        
    }
    
    func appSwitcherWillProcessPaymentInfo(_ appSwitcher: Any) {
        
    }

}
