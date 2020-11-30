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
    static let domain = "http://192.168.11.2:4567"
    var body: some View {
        Text(challenge)
            .padding()
        Button(action: {
            attest()
        }, label: {Text("button")})
    }
    

    func attest() {
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
                    } catch let err {
                        print(err)
                    }
                    DCAppAttestService.shared.generateKey() { keyId, error in
                        guard error == nil else {
                            if let error = error {
                                print(error.localizedDescription)
                            }
                            return
                        }
                        
                        //TODO: save the keyId, if getting a key/pair's keyId successfully.
                        UserDefaults.standard.setValue(keyId, forKey: "attest_key")

                        
                        let root = result["challenge"] as! [String: Any]
                        let uuid = root["uuid"] as! String
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
                                }.resume()

                            }
                        }
                        
                    }

//                    DispatchQueue.main.async {
//                        challenge = sha256.description
//                    }
                    
                }.resume()
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
