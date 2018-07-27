//
//  HealthStore.swift
//  OTFWatch
//
//  Created by Duffett, Eric on 7/27/18.
//  Copyright © 2018 Undaunted Athlete, LLC. All rights reserved.
//

import Foundation
import HealthKit

func checkAvailability() -> Bool {
    if HKHealthStore.isHealthDataAvailable() {
        return true
    } else {
        return false
    }
}

extension HKQuantityType {
    
    static func activeEnergyBurned() -> HKQuantityType {
        return HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)!
    }
    
    static func heartRate() -> HKQuantityType {
        return HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
        
    }
    
}


