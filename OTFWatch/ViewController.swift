//
//  ViewController.swift
//  OTFWatch
//
//  Created by Duffett, Eric on 7/26/18.
//  Copyright © 2018 Undaunted Athlete, LLC. All rights reserved.
//

import UIKit
import HealthKit


class ViewController: UIViewController {
    
    let healthStore = HKHealthStore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let allTypes = Set([HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
                            HKObjectType.quantityType(forIdentifier: .heartRate)!,
                            HKObjectType.quantityType(forIdentifier: .bodyMass)!])
        
        healthStore.requestAuthorization(toShare: allTypes, read: allTypes) { (success, error) in
            if !success {
                // Handle the error here.
                print("Did not get access to health store")
            } else {
                //Can read all types
                print("Got access to health store")
                
            }
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

