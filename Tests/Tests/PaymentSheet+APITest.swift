//
//  PaymentSheet+APITest.swift
//  StripeiOS Tests
//
//  Created by Jaime Park on 6/29/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest
@testable @_spi(STP) import Stripe

class PaymentSheetAPITest: XCTestCase {
    lazy var configuration: PaymentSheet.Configuration = {
        var config = PaymentSheet.Configuration()
        config.apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        return config
    }()
    func fetchPaymentIntent(types: [String], completion: @escaping (Result<(String), Error>) -> Void) {
        STPTestingAPIClient
            .shared()
            .createPaymentIntent(
                withParams: [
                    "amount": 1050,
                    "currency": "eur",
                    "payment_method_types": types,
                ]
            ) { clientSecret, error in
                guard let clientSecret = clientSecret,
                      error == nil
                else {
                    completion(.failure(error!))
                    return
                }

                completion(.success(clientSecret))
            }
    }

    func fetchSetupIntent(types: [String], completion: @escaping (Result<(String), Error>) -> Void) {
        STPTestingAPIClient
            .shared()
            .createSetupIntent(
                withParams: [
                    "payment_method_types": types,
                ]
            ) { clientSecret, error in
                guard let clientSecret = clientSecret,
                      error == nil
                else {
                    completion(.failure(error!))
                    return
                }

                completion(.success(clientSecret))
            }
    }

    func testPaymentSheetLoadWithPaymentIntent() {
        let expectation = XCTestExpectation(description: "Retrieve Payment Intent With Preferences")
        let types = ["ideal", "card", "bancontact", "sofort"]
        let expected = [.card, .iDEAL, .bancontact, .sofort]
            .filter { PaymentSheet.supportedPaymentMethods.contains($0) }
        
        fetchPaymentIntent(types: types) { result in
            switch result {
            case .success(let clientSecret):
                PaymentSheet.load(
                    clientSecret: IntentClientSecret.paymentIntent(clientSecret: clientSecret),
                    configuration: self.configuration
                ) { result in
                    switch result {
                    case .success((let paymentIntent, let paymentMethods)):
                        expectation.fulfill()
                        XCTAssertEqual(paymentIntent.recommendedPaymentMethodTypes, expected)
                        XCTAssertEqual(paymentMethods, [])
                    case .failure(let error):
                        print(error)
                    }
                }
                
            case .failure(let error):
                print(error)
            }
        }
        wait(for: [expectation], timeout: STPTestingNetworkRequestTimeout)
    }
    
    func testPaymentSheetLoadWithSetupIntent() {
        let expectation = XCTestExpectation(description: "Retrieve Setup Intent With Preferences")
        let types = ["ideal", "card", "bancontact", "sofort"]
        let expected: [STPPaymentMethodType] = [.card]
        fetchSetupIntent(types: types) { result in
            switch result {
            case .success(let clientSecret):
                PaymentSheet.load(
                    clientSecret: IntentClientSecret.setupIntent(clientSecret: clientSecret),
                    configuration: self.configuration
                ) { result in
                    switch result {
                    case .success((let setupIntent, let paymentMethods)):
                        expectation.fulfill()
                        XCTAssertEqual(setupIntent.recommendedPaymentMethodTypes, expected)
                        XCTAssertEqual(paymentMethods, [])
                    case .failure(let error):
                        print(error)
                    }
                }
                
            case .failure(let error):
                print(error)
            }
        }
        wait(for: [expectation], timeout: STPTestingNetworkRequestTimeout)
    }
}
