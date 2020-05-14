//
//  LoginViewController.swift
//  TheMovieManager
//
//  Created by Owen LaRosa on 8/13/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var loginViaWebsiteButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        emailTextField.text = ""
        passwordTextField.text = ""
    }
    
    @IBAction func loginTapped(_ sender: UIButton) {
        
        setLoggingIn(true)
        TMDBClient.getRequestToken(completion: handleRequestTokenResponse(success:error:))
    }
    
    @IBAction func loginViaWebsiteTapped() {
   
        setLoggingIn(true)
        TMDBClient.getRequestToken { (success, error) in
            if success {
                DispatchQueue.main.async {
                    UIApplication.shared.open(TMDBClient.Endpoints.webAuth.url, options: [:], completionHandler: self.handleWebsiteResponse(success:))
                }
            }
        }
    }
    
    func handleWebsiteResponse(success: Bool) {
        if success {
            self.setLoggingIn(false)
        }
    }
    
    func handleRequestTokenResponse(success: Bool, error: Error?) {
        if success {
            print(TMDBClient.Auth.requestToken)
                TMDBClient.login(username: self.emailTextField.text ?? "", password: self.passwordTextField.text ?? "", completion: self.handleLoginResponse(success:error:))
            
        }
    }
    
    func handleLoginResponse(success: Bool, error: Error?) {
        
        if success {
            print(TMDBClient.Auth.requestToken)
            TMDBClient.createSessionId(completion: handleSessionResponse(success:error:))
        }
    }
    
    func handleSessionResponse(success: Bool, error: Error?) {
        
        print("loginIn false")
        setLoggingIn(false)
        if success {
            print(TMDBClient.Auth.sessionId)
                self.performSegue(withIdentifier: "completeLogin", sender: nil)
        }
        
    }
    
   func setLoggingIn(_ loggingIn: Bool) {
        if loggingIn {
            activityIndicator.startAnimating()
            
        } else {
            activityIndicator.stopAnimating()
        }
        emailTextField.isEnabled = !loggingIn
        passwordTextField.isEnabled = !loggingIn
        loginButton.isEnabled = !loggingIn
        loginViaWebsiteButton.isEnabled = !loggingIn
    }
}
