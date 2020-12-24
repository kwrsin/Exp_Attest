//
//  ContentView.swift
//  Exp_Artest
//
//  Created by kwrsin on 2020/11/23.
//

import SwiftUI
import DeviceCheck

import CryptoKit

struct ContentView: View {
    @State var challenge:String = "----"
    @State var attestResponse: Int = 0
    @State var premiumContents: String = "----"
    @State var removed = ""
    @State var attestationState: String = "----"
    static let domain = "http://192.168.11.2:4567"
    var body: some View {
        Text(challenge)
            .padding()
        Button(action: {
            getChallenge()
        }, label: {Text("challenge")})
        Text("status: \(attestResponse)")
        Button(action: {
            attest()
        }, label: {Text("Attest")})
        Text(premiumContents)
            .padding()
        Button(action: {
            assert()
        }, label: {Text("Assert")})
        Text(removed)
        Button(action: {
            delete()
        }, label: {Text("Remove")})
        Text("can update attest \(attestationState)")
        Button(action: {
            canUpdateAttestation()
        }, label: {Text("Comfirm")})
    }
    
    func canUpdateAttestation() {
        guard let uuid = UserDefaults.standard.string(forKey: "uuid") else {
            return
        }
        let service = DCAppAttestService.shared
        if service.isSupported {
            let req_challenge = URLRequest(url: URL(string: "\(Self.domain)/can_update_atestation/\(uuid)")!)
            DispatchQueue.global(qos: .userInitiated).async {
                URLSession.shared.dataTask(with: req_challenge) {data, res, error in
                    guard let data = data, let res = res else {
                        return
                    }
                    let httpres = res as! HTTPURLResponse
                    print(httpres.statusCode)
                    
                    var result = [String:Any]()
                    do {
                        result = try JSONSerialization.jsonObject(with: data, options: []) as! [String : Any]
                        let state = result["result"] as! Int
                        DispatchQueue.main.async {
                            attestationState = "\(state)"
                        }
                    } catch let err {
                        print(err)
                    }
                }.resume()
            }
        }
    }
    
    func delete() {
        let keyId = UserDefaults.standard.string(forKey: "attest_key")
        let uuid = UserDefaults.standard.string(forKey: "uuid")
        let request = [
            "challenge": uuid,
        ]
        guard let clientData = try? JSONEncoder().encode(request) else {return}
        let clientDataHash = Data(SHA256.hash(data: clientData))
        let service = DCAppAttestService.shared
        service.generateAssertion(keyId!, clientDataHash: clientDataHash) { assertion, error in
            guard error == nil else {return}
            var req_assertion = URLRequest(url: URL(string: "\(Self.domain)/checked")!)
            
            req_assertion.httpMethod = "DELETE"

            var attestationObject = [String: Any]()
            attestationObject["clientData"] = clientData.base64EncodedString(options: [])
                .addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed)!
            attestationObject["assertion"] = assertion!.base64EncodedString(options: [])
                .addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed)!
            var params = [String]()
            attestationObject.forEach { key, value in
                params.append("\(key)=\(value)")
            }
            req_assertion.httpBody = params.joined(separator: "&").data(using: .utf8)
            req_assertion.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            
            URLSession.shared.dataTask(with: req_assertion) {data, res, error in
                guard let data = data, let res = res else {
                    if let error = error {
                        print(error.localizedDescription)
                    }
                    
                    
                    
                    return
                }
                let httpres = res as! HTTPURLResponse
                print(httpres.statusCode)
                
                var result = [String:Any]()
                do {
                    result = try JSONSerialization.jsonObject(with: data, options: []) as! [String : Any]
                } catch let err {
                    print(err)
                }
                let state = result["result"] as! Int
                DispatchQueue.main.async {
                    removed = "\(state)"
                }
            }.resume()

        }

    }
    
    func assert() {
        let keyId = UserDefaults.standard.string(forKey: "attest_key")
        let uuid = UserDefaults.standard.string(forKey: "uuid")
        let request = [
            "action": "get_contents",
            "challenge": uuid,
        ]
        guard let clientData = try? JSONEncoder().encode(request) else {return}
        let clientDataHash = Data(SHA256.hash(data: clientData))
        let service = DCAppAttestService.shared
        service.generateAssertion(keyId!, clientDataHash: clientDataHash) { assertion, error in
            guard error == nil else {return}
            var req_assertion = URLRequest(url: URL(string: "\(Self.domain)/assertion")!)
            
            req_assertion.httpMethod = "POST"

            var attestationObject = [String: Any]()
            attestationObject["clientData"] = clientData.base64EncodedString(options: [])
                .addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed)!
            attestationObject["assertion"] = assertion!.base64EncodedString(options: [])
                .addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed)!
            var params = [String]()
            attestationObject.forEach { key, value in
                params.append("\(key)=\(value)")
            }
            req_assertion.httpBody = params.joined(separator: "&").data(using: .utf8)
            req_assertion.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            
            URLSession.shared.dataTask(with: req_assertion) {data, res, error in
                guard let data = data, let res = res else {
                    if let error = error {
                        print(error.localizedDescription)
                    }
                    
                    
                    
                    return
                }
                let httpres = res as! HTTPURLResponse
                print(httpres.statusCode)
                
                var result = [String:Any]()
                do {
                    result = try JSONSerialization.jsonObject(with: data, options: []) as! [String : Any]
                } catch let err {
                    print(err)
                }
                let contents = result["result"] as! String
                DispatchQueue.main.async {
                    premiumContents = contents
                }
            }.resume()

        }
    }
    
    func getChallenge() {
        let service = DCAppAttestService.shared
        if service.isSupported {
            let req_challenge = URLRequest(url: URL(string: "\(Self.domain)/challenge")!)
            DispatchQueue.global(qos: .userInitiated).async {
                URLSession.shared.dataTask(with: req_challenge) {data, res, error in
                    guard let data = data, let res = res else {
                        return
                    }
                    let httpres = res as! HTTPURLResponse
                    print(httpres.statusCode)
                    
                    var result = [String:Any]()
                    do {
                        result = try JSONSerialization.jsonObject(with: data, options: []) as! [String : Any]
                        let root = result["challenge"] as! [String: Any]
                        let uuid = root["uuid"] as! String
                        challenge = uuid
                    } catch let err {
                        print(err)
                    }
                }.resume()
            }
        }
        

    }

    func attest() {
        if challenge.isEmpty == false {
            DCAppAttestService.shared.generateKey() { keyId, error in
                guard error == nil else {
                    if let error = error {
                        print(error.localizedDescription)
                    }
                    return
                }
                
                let uuid = challenge
                let hashedChallenge = Data(SHA256.hash(data: uuid.data(using: .utf8)!))
                DCAppAttestService.shared.attestKey(keyId!, clientDataHash: hashedChallenge) { attestation, error in
                    if let error = error {
                        //FIXME: if gettting a serverUnavailable error retry it again. if you got aother error, recreate key again.
                        print(error.localizedDescription)
                        return
                    }
                    
                    if let attestation = attestation, let keyId = keyId {
                        var req_attestation = URLRequest(url: URL(string: "\(Self.domain)/attestation/\(uuid)")!)
                        
                        req_attestation.httpMethod = "POST"

                        var attestationObject = [String: Any]()
                        attestationObject["attestation"] = attestation.base64EncodedString(options: [])
                            .addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed)!
                        attestationObject["keyId"] = keyId
                            .addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed)!
                        var params = [String]()
                        attestationObject.forEach { key, value in
                            params.append("\(key)=\(value)")
                        }
                        req_attestation.httpBody = params.joined(separator: "&").data(using: .utf8)
                        req_attestation.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                        
                        URLSession.shared.dataTask(with: req_attestation) {data, res, error in
                            guard let data = data, let res = res else {
                                if let error = error {
                                    print(error.localizedDescription)
                                }
                                
                                return
                            }
                            let httpres = res as! HTTPURLResponse
                            print(httpres.statusCode)
                            //TODO: save the keyId, if getting a key/pair's keyId successfully.
                            UserDefaults.standard.setValue(keyId, forKey: "attest_key")
                            UserDefaults.standard.setValue(uuid, forKey: "uuid")
                            var result = [String:Any]()
                            do {
                                result = try JSONSerialization.jsonObject(with: data, options: []) as! [String : Any]
                            } catch let err {
                                print(err)
                            }
                            let status = result["result"] as! Int
                            DispatchQueue.main.async {
                                attestResponse = status
                            }
                        }.resume()

                    }
                }
                
            }
        }
        
    }
}

//REF: https://stackoverflow.com/questions/38798273/ios-swift-post-request-with-binary-body
extension CharacterSet {
    static let urlQueryValueAllowed: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="

        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: generalDelimitersToEncode + subDelimitersToEncode)
        return allowed
    }()
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
