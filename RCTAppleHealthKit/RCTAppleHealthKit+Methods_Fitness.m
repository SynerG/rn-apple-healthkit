//
//  RCTAppleHealthKit+Methods_Fitness.m
//  RCTAppleHealthKit
//
//  Created by Greg Wilson on 2016-06-26.
//  Copyright © 2016 Greg Wilson. All rights reserved.
//

#import "RCTAppleHealthKit+Methods_Fitness.h"
#import "RCTAppleHealthKit+Queries.h"
#import "RCTAppleHealthKit+Utils.h"

#import <React/RCTBridgeModule.h>
#import <React/RCTEventDispatcher.h>
#import <SGTimeLogger.h>

@implementation RCTAppleHealthKit (Methods_Fitness)


- (void)fitness_getStepCountOnDay:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback
{
    NSDate *date = [RCTAppleHealthKit dateFromOptions:input key:@"date" withDefault:[NSDate date]];

    if(date == nil) {
        callback(@[RCTMakeError(@"could not parse date from options.date", nil, nil)]);
        return;
    }

    HKQuantityType *stepCountType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    HKUnit *stepsUnit = [HKUnit countUnit];

    [self fetchSumOfSamplesOnDayForType:stepCountType
                                   unit:stepsUnit
                                    day:date
                             completion:^(double value, NSDate *startDate, NSDate *endDate, NSError *error) {
        if (!value) {
            NSLog(@"could not fetch step count for day: %@", error);
            callback(@[RCTMakeError(@"could not fetch step count for day", error, nil)]);
            return;
        }

         NSDictionary *response = @{
                 @"value" : @(value),
                 @"startDate" : [RCTAppleHealthKit buildISO8601StringFromDate:startDate],
                 @"endDate" : [RCTAppleHealthKit buildISO8601StringFromDate:endDate],
         };

        callback(@[[NSNull null], response]);
    }];
}

- (void)fitness_getSamples:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback
{
    HKUnit *unit = [RCTAppleHealthKit hkUnitFromOptions:input key:@"unit" withDefault:[HKUnit countUnit]];
    NSUInteger limit = [RCTAppleHealthKit uintFromOptions:input key:@"limit" withDefault:HKObjectQueryNoLimit];
    BOOL ascending = [RCTAppleHealthKit boolFromOptions:input key:@"ascending" withDefault:false];
    NSString *type = [RCTAppleHealthKit stringFromOptions:input key:@"type" withDefault:@"Walking"];
    NSDate *startDate = [RCTAppleHealthKit dateFromOptions:input key:@"startDate" withDefault:[NSDate date]];
    NSDate *endDate = [RCTAppleHealthKit dateFromOptions:input key:@"endDate" withDefault:[NSDate date]];
    
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionStrictStartDate];
    
    HKSampleType *samplesType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    if ([type isEqual:@"Walking"]) {
        samplesType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    } else if ([type isEqual:@"StairClimbing"]) {
        samplesType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierFlightsClimbed];
    } else if ([type isEqual:@"Running"]){
        samplesType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning];
        unit = [HKUnit mileUnit];
    } else if ([type isEqual:@"Cycling"]){
        samplesType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceCycling];
        unit = [HKUnit mileUnit];
    } else if ([type isEqual:@"Workout"]){
        samplesType = [HKObjectType workoutType];
    }
    
    [self fetchSamplesOfType:samplesType
                                unit:unit
                           predicate:predicate
                           ascending:ascending
                               limit:limit
                          completion:^(NSArray *results, NSError *error) {
                              if(results){
                                  callback(@[[NSNull null], results]);
                                  return;
                              } else {
                                  NSLog(@"error getting active energy burned samples: %@", error);
                                  callback(@[RCTMakeError(@"error getting active energy burned samples", nil, nil)]);
                                  return;
                              }
                          }];
}

- (void)fitness_setObserver:(NSDictionary *)input
{
    HKUnit *unit = [RCTAppleHealthKit hkUnitFromOptions:input key:@"unit" withDefault:[HKUnit countUnit]];
    NSString *type = [RCTAppleHealthKit stringFromOptions:input key:@"type" withDefault:@"Walking"];
    
    HKSampleType *samplesType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    if ([type isEqual:@"Walking"]) {
        samplesType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    } else if ([type isEqual:@"StairClimbing"]) {
        samplesType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierFlightsClimbed];
    } else if ([type isEqual:@"Running"]){
        samplesType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning];
        unit = [HKUnit mileUnit];
    } else if ([type isEqual:@"Cycling"]){
        samplesType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceCycling];
        unit = [HKUnit mileUnit];
    } else if ([type isEqual:@"Workout"]){
        samplesType = [HKObjectType workoutType];
    }
    
    [self setObserverForType:samplesType unit:unit];
}


- (void)fitness_getDailyStepSamples:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback
{
    HKUnit *unit = [RCTAppleHealthKit hkUnitFromOptions:input key:@"unit" withDefault:[HKUnit countUnit]];
    NSUInteger limit = [RCTAppleHealthKit uintFromOptions:input key:@"limit" withDefault:HKObjectQueryNoLimit];
    BOOL ascending = [RCTAppleHealthKit boolFromOptions:input key:@"ascending" withDefault:false];
    NSDate *startDate = [RCTAppleHealthKit dateFromOptions:input key:@"startDate" withDefault:nil];
    NSDate *endDate = [RCTAppleHealthKit dateFromOptions:input key:@"endDate" withDefault:[NSDate date]];
    if(startDate == nil){
        callback(@[RCTMakeError(@"startDate is required in options", nil, nil)]);
        return;
    }

    HKQuantityType *stepCountType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];

    [self fetchCumulativeSumStatisticsCollection:stepCountType
                                            unit:unit
                                       startDate:startDate
                                         endDate:endDate
                                       ascending:ascending
                                           limit:limit
                                      completion:^(NSArray *arr, NSError *err){
        if (err != nil) {
            NSLog(@"error with fetchCumulativeSumStatisticsCollection: %@", err);
            callback(@[RCTMakeError(@"error with fetchCumulativeSumStatisticsCollection", err, nil)]);
            return;
        }
        callback(@[[NSNull null], arr]);
    }];
}


- (void)fitness_saveSteps:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback
{
    double value = [RCTAppleHealthKit doubleFromOptions:input key:@"value" withDefault:(double)0];
    NSDate *startDate = [RCTAppleHealthKit dateFromOptions:input key:@"startDate" withDefault:nil];
    NSDate *endDate = [RCTAppleHealthKit dateFromOptions:input key:@"endDate" withDefault:[NSDate date]];

    if(startDate == nil || endDate == nil){
        callback(@[RCTMakeError(@"startDate and endDate are required in options", nil, nil)]);
        return;
    }

    HKUnit *unit = [HKUnit countUnit];
    HKQuantity *quantity = [HKQuantity quantityWithUnit:unit doubleValue:value];
    HKQuantityType *type = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    HKQuantitySample *sample = [HKQuantitySample quantitySampleWithType:type quantity:quantity startDate:startDate endDate:endDate];

    [self.healthStore saveObject:sample withCompletion:^(BOOL success, NSError *error) {
        if (!success) {
            NSLog(@"An error occured saving the step count sample %@. The error was: %@.", sample, error);
            callback(@[RCTMakeError(@"An error occured saving the step count sample", error, nil)]);
            return;
        }
        callback(@[[NSNull null], @(value)]);
    }];
}


- (void)fitness_initializeStepEventObserver:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback
{
    HKSampleType *sampleType =
    [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];

    HKObserverQuery *query =
    [[HKObserverQuery alloc]
     initWithSampleType:sampleType
     predicate:nil
     updateHandler:^(HKObserverQuery *query,
                     HKObserverQueryCompletionHandler completionHandler,
                     NSError *error) {

         if (error) {
             // Perform Proper Error Handling Here...
             NSLog(@"*** An error occured while setting up the stepCount observer. %@ ***", error.localizedDescription);
             callback(@[RCTMakeError(@"An error occured while setting up the stepCount observer", error, nil)]);
             return;
         }

          [self.bridge.eventDispatcher sendAppEventWithName:@"change:steps"
                                                       body:@{@"name": @"change:steps"}];

         // If you have subscribed for background updates you must call the completion handler here.
         // completionHandler();

     }];

    [self.healthStore executeQuery:query];
}




- (void)fitness_registerObserversAtLaunch{
    NSLog(@"Called fitness_registerObserversAtLaunch!!");
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"AllBackgroundObserversEnabled"]) {
        NSLog(@"Option BackgroundObserversEnabled is enabled. Calling fitness_enableAllBackgroundObservers");

        if (!self.healthStore){
            NSLog(@"There was no healthStore yet. Initializing from register at launch");
            [SGTimeLogger log:@"N. ObserversAtLaunch enabled. Initializing HK store too"];
            self.healthStore = [[HKHealthStore alloc] init];
        } else {
            [SGTimeLogger log:@"N. ObserversAtLaunch enabled. HK store was already init"];
            NSLog(@"There was a healthStore already, so do not create a new one from register at launch");
        }

        [self fitness_enableAllBackgroundObservers];
    } else {
        [SGTimeLogger log:@"N. ObserversAtLaunch not enabled"];
        NSLog(@"Option BackgroundObserversEnabled is disabled");
    }
}

- (void)fitness_setAndDoEnableAllBackgroundObservers:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback
{
    NSLog(@"Called fitness_setAndDoEnableAllBackgroundObservers");
    NSLog(@"Setting in NSUserDefaults AllBackgroundObserversEnabled");
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:@"AllBackgroundObserversEnabled"];
    // TODO: Have a callback in enableAllBackgroundObservers and notify of internal errors in that function to JS
    [SGTimeLogger log:@"N. Set df enable ObserversAtLaunch"];
    [self fitness_enableAllBackgroundObservers];
    callback(@[[NSNull null], @"Completed setAndDoEnableAllBackgroundObservers"]);
}

- (void)fitness_enableAllBackgroundObservers
{
    NSLog(@"Called fitness_enableAllBackgroundObservers...");
    HKSampleType *sampleType =
    [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    [SGTimeLogger log:@"N. fitness_enableAllBackgroundObservers"];
    HKObserverQuery *query =
    [[HKObserverQuery alloc]
     initWithSampleType:sampleType
     predicate:nil
     updateHandler:^(HKObserverQuery *query,
                     HKObserverQueryCompletionHandler completionHandler,
                     NSError *error) {

         if (error) {
             // Perform Proper Error Handling Here...
             [SGTimeLogger log:[NSString stringWithFormat:@"N. Error in HKObserverQuery: %@", error.localizedDescription]];
             NSLog(@"*** An error occured while setting up the stepCount observer. %@ ***", error.localizedDescription);
             //callback(@[RCTMakeError(@"An error occured while setting up the stepCount observer", error, nil)]);
             return;
         }
         [SGTimeLogger log:@"N. Observer called"];
         NSLog(@"Change steps event received in Native library");


         // Save completionHandler for later
         if (!self.completionHandlers){
             NSLog(@"Initializing self.completionHandlers...");
             self.completionHandlers = [[NSMutableDictionary alloc] init];
         }
         NSMutableDictionary * handlersForType = [self.completionHandlers objectForKey:HKQuantityTypeIdentifierStepCount];
         NSLog(@"handlersForType is: %@", handlersForType);
         if (!handlersForType){
             NSLog(@"Initializing handlersForType...");
             handlersForType = [[NSMutableDictionary alloc] init];
             [self.completionHandlers setObject:handlersForType forKey:HKQuantityTypeIdentifierStepCount];
         }

         NSLog(@"Preparing id str");
         NSDate *currDate = [NSDate date];
         double timePassed_ms = [currDate timeIntervalSinceReferenceDate];
         NSString *key= [NSString stringWithFormat:@"%f", timePassed_ms];

         NSLog(@"Saving completionHandler in dictionary");
         NSLog(@"Completion handler is: %@", completionHandler);

         NSLog(@"Copy completion handler");
         void(^completionHandlerCopy)(void) = [completionHandler copy];//Block_copy(handler); // Tmb vale: [handler copy];
         NSLog(@"Copy completion handler result: %@", completionHandlerCopy);

         NSLog(@"Setting completion handler copy in dictionary...");
         [handlersForType setObject:completionHandlerCopy forKey:key];
         NSLog(@"Result of Set completion handler copy in dic: %@", handlersForType);
         NSLog(@"Result in full completionHandlers dic: %@", self.completionHandlers);


         // JS listening status and sending event
         if (!self.listeningStatus){
             NSLog(@"Initializing listeningStatus dictionary");
             self.listeningStatus = [[NSMutableDictionary alloc] init];
         }

         // NSNumber *yesNumber = @YES
         // [parameters setValue:yesNumber forKey:@"news"];
         // [[myDictionary objectForKey:theKey] boolValue]

         //[self.listeningStatus objectForKey:HKQuantityTypeIdentifierStepCount];

         BOOL isListeningType = [[self.listeningStatus objectForKey:HKQuantityTypeIdentifierStepCount] boolValue];

         NSLog(@"Got listening status for steps: %d", isListeningType);
         if (isListeningType){
             [SGTimeLogger log:[NSString stringWithFormat:@"N. js is listening. Sending event: %@", key]];
             NSLog(@"Is already listening for steps. Sending evento to JS directly");
             [self.bridge.eventDispatcher sendAppEventWithName:@"change:steps"
                                                          body:@{
                                                                 @"name": @"change:steps",
                                                                 @"completionType": [NSString stringWithFormat:@"%@", HKQuantityTypeIdentifierStepCount],
                                                                 @"completionId": key
                                                                 }];
         } else {
             [SGTimeLogger log:@"N. js is not listening yet"];
             NSLog(@"It is not listening type yet. Do nothing else");
         }

         // If you have subscribed for background updates you must call the completion handler here.
         //completionHandler();

     }];

    [self.healthStore executeQuery:query];

    [SGTimeLogger log:@"N. Enabling BG delivery"];
    [self.healthStore enableBackgroundDeliveryForType:sampleType frequency:HKUpdateFrequencyImmediate withCompletion:^(BOOL success, NSError * _Nullable error) {
        if (!success) {
            NSLog(@"failed to enable background delivery");
        } else {
            NSLog(@"Background delivery enabled successfully!");
        }
    }];
    NSLog(@"End of fitness_enableAllBackgroundObservers");
}

- (void)fitness_readyToReceiveAllObserverEvents:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback
{
    NSLog(@"JS has signalled readyToReceiveAllObserverEvents. See if pending events to notify");

    [SGTimeLogger log:@"N. js has signalled is ready"];
    if (!self.listeningStatus){
        NSLog(@"Initializing listeningStatus dictionary from ready");
        self.listeningStatus = [[NSMutableDictionary alloc] init];
    }

    // Process step events
    NSLog(@"Setting Step listening as ready");
    [self.listeningStatus setObject:@YES forKey:HKQuantityTypeIdentifierStepCount];

    // If there were step events already registered, loop through them and notify them
    NSLog(@"completionHandlers was: %@", self.completionHandlers);
    if (self.completionHandlers){
        NSLog(@"CompletionHandlers dic was initialized...");
        NSMutableDictionary * handlersForType = [self.completionHandlers objectForKey:HKQuantityTypeIdentifierStepCount];
        NSLog(@"handlersForType step was: %@", handlersForType);
        if (handlersForType){
            NSLog(@"Handlers for steps was Initialized. Loop it");
            for (id key in handlersForType){
                NSLog(@"Got key: %@. Getting completionHandler just for fun", key);
                void(^completionHandler)(void) = [handlersForType objectForKey:key];
                NSLog(@"Got completionHandler for fun: %@", completionHandler);
                NSLog(@"Sending event for type: %@ and key: %@", HKQuantityTypeIdentifierStepCount, key);
                [SGTimeLogger log:[NSString stringWithFormat:@"N. Notifying about: %@", key]];
                [self.bridge.eventDispatcher sendAppEventWithName:@"change:steps"
                                                             body:@{
                                                                    @"name": @"change:steps",
                                                                    @"completionType": [NSString stringWithFormat:@"%@", HKQuantityTypeIdentifierStepCount],
                                                                    @"completionId": key
                                                                    }];
            }
            NSLog(@"Done looping");
        } else {
            [SGTimeLogger log:@"N. No step comp handlers to notify"];
            NSLog(@"There were no completionHandlers for steps yet");
        }
    } else {
        [SGTimeLogger log:@"N. No comp handlers in general to notify"];
        NSLog(@"There were no completionHandlers in general");
    }

    // TODO: Implement HKWorkouts too

    // Not required, but:
    callback(@[[NSNull null], @"All pending events have been emited from Native"]);
}

- (void)fitness_callObserverCompletionHandler:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback
{
    NSLog(@"Native fitness_callObserverCompletionHandler...");
    NSString *completionType = [input objectForKey:@"completionType"];
    NSString *completionId = [input objectForKey:@"completionId"];
    NSLog(@"Recovered from input. completionType: %@ completionId: %@", completionType, completionId);

    NSLog(@"self.completionHandlers is: %@", self.completionHandlers);
    if (!self.completionHandlers){
        [SGTimeLogger log:[NSString stringWithFormat:@"N. Had to call comp hand %@, but compHands no init yet!", completionId]];
        NSLog(@"WARN: There were no completionHandlers to call!!");
        return;
    }

    NSMutableDictionary * handlersForType = [self.completionHandlers objectForKey:completionType];
    NSLog(@"handlers for recovered type is: %@", handlersForType);
    if(!handlersForType){
        [SGTimeLogger log:[NSString stringWithFormat:@"N. Had to call comp hand %@, but compHands no handlersForType yet!", completionId]];
        NSLog(@"WARN: There were no completionHandlers for this type to call!!");
        return;
    }

    void(^completionHandler)(void) = [handlersForType objectForKey:completionId];
    NSLog(@"Recovered completionHandler to call: %@", completionHandler);
    if (completionHandler){
        completionHandler();
        [SGTimeLogger log:[NSString stringWithFormat:@"N. Called comp hand: %@", completionId]];
        NSLog(@"Finally called completion handler!");
        [handlersForType removeObjectForKey:completionId];
        NSLog(@"Removed completion handler. Now handlersForType is: %@", handlersForType);
    } else {
        [SGTimeLogger log:[NSString stringWithFormat:@"N. Had to call comp hand %@, but does not exist!", completionId]];
        NSLog(@"There was no completion handler to call");
    }


    // Not required, but:
    callback(@[[NSNull null], @"Completion handler has been called from Native"]);
}

// NOTE: Not really used in new implementation!
- (void)fitness_initializeStepEventObserverWithBackground:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback
{
    HKSampleType *sampleType =
    [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];

    HKObserverQuery *query =
    [[HKObserverQuery alloc]
     initWithSampleType:sampleType
     predicate:nil
     updateHandler:^(HKObserverQuery *query,
                     HKObserverQueryCompletionHandler completionHandler,
                     NSError *error) {

         if (error) {
             // Perform Proper Error Handling Here...
             NSLog(@"*** An error occured while setting up the stepCount observer. %@ ***", error.localizedDescription);
             callback(@[RCTMakeError(@"An error occured while setting up the stepCount observer", error, nil)]);
             return;
         }
         [SGTimeLogger log:@"Native Observer called"];
         NSLog(@"Change steps event received in Native library");

         [self.bridge.eventDispatcher sendAppEventWithName:@"change:steps"
                                                      body:@{@"name": @"change:steps"}];

         // If you have subscribed for background updates you must call the completion handler here.
         completionHandler();

     }];

    [self.healthStore executeQuery:query];


    [self.healthStore enableBackgroundDeliveryForType:sampleType frequency:HKUpdateFrequencyImmediate withCompletion:^(BOOL success, NSError * _Nullable error) {
        if (!success) {
            NSLog(@"failed to enable background delivery");
        } else {
            NSLog(@"Background delivery enabled successfully!");
        }
    }];
}





- (void)fitness_getDistanceWalkingRunningOnDay:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback
{
    HKUnit *unit = [RCTAppleHealthKit hkUnitFromOptions:input key:@"unit" withDefault:[HKUnit meterUnit]];
    NSDate *date = [RCTAppleHealthKit dateFromOptions:input key:@"date" withDefault:[NSDate date]];

    HKQuantityType *quantityType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning];

    [self fetchSumOfSamplesOnDayForType:quantityType unit:unit day:date completion:^(double distance, NSDate *startDate, NSDate *endDate, NSError *error) {
        if (!distance) {
            NSLog(@"ERROR getting DistanceWalkingRunning: %@", error);
            callback(@[RCTMakeError(@"ERROR getting DistanceWalkingRunning", error, nil)]);
            return;
        }

        NSDictionary *response = @{
                @"value" : @(distance),
                @"startDate" : [RCTAppleHealthKit buildISO8601StringFromDate:startDate],
                @"endDate" : [RCTAppleHealthKit buildISO8601StringFromDate:endDate],
        };


        callback(@[[NSNull null], response]);
    }];
}

- (void)fitness_getDailyDistanceWalkingRunningSamples:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback
{
    HKUnit *unit = [RCTAppleHealthKit hkUnitFromOptions:input key:@"unit" withDefault:[HKUnit meterUnit]];
    NSUInteger limit = [RCTAppleHealthKit uintFromOptions:input key:@"limit" withDefault:HKObjectQueryNoLimit];
    BOOL ascending = [RCTAppleHealthKit boolFromOptions:input key:@"ascending" withDefault:false];
    NSDate *startDate = [RCTAppleHealthKit dateFromOptions:input key:@"startDate" withDefault:nil];
    NSDate *endDate = [RCTAppleHealthKit dateFromOptions:input key:@"endDate" withDefault:[NSDate date]];
    if(startDate == nil){
        callback(@[RCTMakeError(@"startDate is required in options", nil, nil)]);
        return;
    }
    
    HKQuantityType *quantityType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning];
    
    [self fetchCumulativeSumStatisticsCollection:quantityType
                                            unit:unit
                                       startDate:startDate
                                         endDate:endDate
                                       ascending:ascending
                                           limit:limit
                                      completion:^(NSArray *arr, NSError *err){
                                          if (err != nil) {
                                              NSLog(@"error with fetchCumulativeSumStatisticsCollection: %@", err);
                                              callback(@[RCTMakeError(@"error with fetchCumulativeSumStatisticsCollection", err, nil)]);
                                              return;
                                          }
                                          callback(@[[NSNull null], arr]);
                                      }];
}

- (void)fitness_getDistanceCyclingOnDay:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback
{
    HKUnit *unit = [RCTAppleHealthKit hkUnitFromOptions:input key:@"unit" withDefault:[HKUnit meterUnit]];
    NSDate *date = [RCTAppleHealthKit dateFromOptions:input key:@"date" withDefault:[NSDate date]];

    HKQuantityType *quantityType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceCycling];

    [self fetchSumOfSamplesOnDayForType:quantityType unit:unit day:date completion:^(double distance, NSDate *startDate, NSDate *endDate, NSError *error) {
        if (!distance) {
            NSLog(@"ERROR getting DistanceCycling: %@", error);
            callback(@[RCTMakeError(@"ERROR getting DistanceCycling", error, nil)]);
            return;
        }

        NSDictionary *response = @{
                @"value" : @(distance),
                @"startDate" : [RCTAppleHealthKit buildISO8601StringFromDate:startDate],
                @"endDate" : [RCTAppleHealthKit buildISO8601StringFromDate:endDate],
        };

        callback(@[[NSNull null], response]);
    }];
}

- (void)fitness_getDailyDistanceCyclingSamples:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback
{
    HKUnit *unit = [RCTAppleHealthKit hkUnitFromOptions:input key:@"unit" withDefault:[HKUnit meterUnit]];
    NSUInteger limit = [RCTAppleHealthKit uintFromOptions:input key:@"limit" withDefault:HKObjectQueryNoLimit];
    BOOL ascending = [RCTAppleHealthKit boolFromOptions:input key:@"ascending" withDefault:false];
    NSDate *startDate = [RCTAppleHealthKit dateFromOptions:input key:@"startDate" withDefault:nil];
    NSDate *endDate = [RCTAppleHealthKit dateFromOptions:input key:@"endDate" withDefault:[NSDate date]];
    if(startDate == nil){
        callback(@[RCTMakeError(@"startDate is required in options", nil, nil)]);
        return;
    }
    
    HKQuantityType *quantityType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceCycling];
    
    [self fetchCumulativeSumStatisticsCollection:quantityType
                                            unit:unit
                                       startDate:startDate
                                         endDate:endDate
                                       ascending:ascending
                                           limit:limit
                                      completion:^(NSArray *arr, NSError *err){
                                          if (err != nil) {
                                              NSLog(@"error with fetchCumulativeSumStatisticsCollection: %@", err);
                                              callback(@[RCTMakeError(@"error with fetchCumulativeSumStatisticsCollection", err, nil)]);
                                              return;
                                          }
                                          callback(@[[NSNull null], arr]);
                                      }];
}

- (void)fitness_getFlightsClimbedOnDay:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback
{
    HKUnit *unit = [HKUnit countUnit];
    NSDate *date = [RCTAppleHealthKit dateFromOptions:input key:@"date" withDefault:[NSDate date]];

    HKQuantityType *quantityType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierFlightsClimbed];

    [self fetchSumOfSamplesOnDayForType:quantityType unit:unit day:date completion:^(double count, NSDate *startDate, NSDate *endDate, NSError *error) {
        if (!count) {
            NSLog(@"ERROR getting FlightsClimbed: %@", error);
            callback(@[RCTMakeError(@"ERROR getting FlightsClimbed", error, nil), @(count)]);
            return;
        }

        NSDictionary *response = @{
                @"value" : @(count),
                @"startDate" : [RCTAppleHealthKit buildISO8601StringFromDate:startDate],
                @"endDate" : [RCTAppleHealthKit buildISO8601StringFromDate:endDate],
        };

        callback(@[[NSNull null], response]);
    }];
}

- (void)fitness_getDailyFlightsClimbedSamples:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback
{
    HKUnit *unit = [RCTAppleHealthKit hkUnitFromOptions:input key:@"unit" withDefault:[HKUnit countUnit]];
    NSUInteger limit = [RCTAppleHealthKit uintFromOptions:input key:@"limit" withDefault:HKObjectQueryNoLimit];
    BOOL ascending = [RCTAppleHealthKit boolFromOptions:input key:@"ascending" withDefault:false];
    NSDate *startDate = [RCTAppleHealthKit dateFromOptions:input key:@"startDate" withDefault:nil];
    NSDate *endDate = [RCTAppleHealthKit dateFromOptions:input key:@"endDate" withDefault:[NSDate date]];
    if(startDate == nil){
        callback(@[RCTMakeError(@"startDate is required in options", nil, nil)]);
        return;
    }
    
    HKQuantityType *quantityType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierFlightsClimbed];
    
    [self fetchCumulativeSumStatisticsCollection:quantityType
                                            unit:unit
                                       startDate:startDate
                                         endDate:endDate
                                       ascending:ascending
                                           limit:limit
                                      completion:^(NSArray *arr, NSError *err){
                                          if (err != nil) {
                                              NSLog(@"error with fetchCumulativeSumStatisticsCollection: %@", err);
                                              callback(@[RCTMakeError(@"error with fetchCumulativeSumStatisticsCollection", err, nil)]);
                                              return;
                                          }
                                          callback(@[[NSNull null], arr]);
                                      }];
}

@end
