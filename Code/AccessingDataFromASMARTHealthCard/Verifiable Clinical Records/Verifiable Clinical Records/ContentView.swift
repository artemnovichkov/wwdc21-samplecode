/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The main view of the demo app.
*/

import SwiftUI
import Combine
import HealthKit

var cancellable: Cancellable? = nil

struct ContentView: View {
    
    let exampleJWS = "eyJ6aXAiOiJERUYiLCJhbGciOiJFUzI1NiIsImtpZCI6IjNLZmRnLVh3UC03Z1h5eXd0VWZVQUR3QnVtRE9QS01ReC1pRUxMMTFXOXMifQ.3ZJLb9swEIT_SrC9ynqltS3d6gRI20NRoGkuhQ80tbYY8CGQlBA30H_vLu0ALRDn1FN1W3H4cWbIZ1AhQAt9jENoiyIY4WOPQsc-l8J3ocAnYQaNoSDhiB4ysLs9tNWyWi_LdXPd5OvVMoNJQvsM8TggtD8v496dhgUPhLqsU8aMVv0SUTn7plC6SXVVA9sMpMcObVRCfx93jygjW9r3yj-gD8xp4X1e5hXx-O9mtJ1G1ngMbvQS75N9OC9k5zggndZEOzmhA_yRMhJ51PqH1yR42d-WJHgZXgF_ozi0nzsUBk8QYZQmHny0pPEhnXFQE1ru8Yvred7ksJ0p4E5R-FsRmVU1H6pFWS3qEuY5e9VN9babz39XHKKIY0hx-cIj8gVNQkpl8cZ1iSBdp-whGQ_HENGcnw7dTK9XufOHgpstguoKOT0RQKadUJcrmLdzBsO5gmRnjx4te_uzQRI5KUefljjsvTInRJ0ClxyLqto7b-g9shcho_OM7FQYtEh1bm6u7tCiF_rqkwuDikJTUVSidvHraHa8Fcr0VRcbrP_LBuvmXze44oWZvt8.O_jx0R_jbQ4d-TJ6n_ntSRIVDZCuW1sBZdEKl77ahwWY_P9FzwfnyM-dmddgpBhbZslc9L3fpGEmJXnXxY6mBA"
    
    @State var buttonText = "Not yet verified"
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack {
                Text("Trigger a HealthKit query to request verifiable health records of the “covid19” and “vaccination” type.")
                Button(action: {
                    requestVerifiableHealthRecords()
                }) {
                    BlueButtonContent(text: "Request Samples")
                }
                .background(Color.blue)
                .cornerRadius(12)
            }
            
            Spacer()
            
            VStack {
                Text("Verify the signature on a hardcoded example JWS.")
                
                Button(action: {
                    verify(jwsString: exampleJWS)
                }) {
                    BlueButtonContent(text: "Verify Example Signature")
                }
                .background(Color.blue)
                .cornerRadius(12)
            }
            
            Spacer()
            Text(buttonText)
            Spacer()
        }.padding()
    }
    
    private func requestVerifiableHealthRecords() {
        let healthStore = HKHealthStore()
        let credentialTypes = ["https://smarthealth.cards#immunization", "https://smarthealth.cards#covid19"]
                               
        // For demo, ask for all records, regardless of their relevant date.
        let dateInterval = DateInterval(start: .distantPast, end: .now)
        let predicate = HKQuery.predicateForVerifiableClinicalRecords(withRelevantDateWithin: dateInterval)
       
        let query = HKVerifiableClinicalRecordQuery(recordTypes: credentialTypes, predicate: predicate) { (query, samplesOrNil, errorOrNil) in
            guard let sample = samplesOrNil?.first else {
                buttonText = "API returned no data."
                return
            }
            
            let sampleString = String(data: sample.jwsRepresentation, encoding: .utf8)!
            verify(jwsString: sampleString)
        }
       
       // Run the query.
       healthStore.execute(query)
    }
    
    private func verify(jwsString: String) {
        do {
            let parsedJWS = try JWS(from: jwsString)
            cancellable = parsedJWS.verifySignature().sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    buttonText = "\(error)"
                case .finished:
                    break
                }
            }, receiveValue: { verified in
                if verified {
                    buttonText = "Verified! ✅"
                } else {
                    buttonText = "Failed to verify ❌"
                }
            })
        } catch {
            buttonText = "Failed to parse JWS \(error)"
        }
    }
}
