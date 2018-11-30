//
//  RCTAppleHealthKit+Methods_Fitness.h
//  RCTAppleHealthKit
//
//  Created by Greg Wilson on 2016-06-26.
//  Copyright © 2016 Greg Wilson. All rights reserved.
//

#import "RCTAppleHealthKit.h"

@interface RCTAppleHealthKit (Methods_Fitness)

- (void)fitness_getStepCountOnDay:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback;
- (void)fitness_getSamples:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback;
- (void)fitness_setObserver:(NSDictionary *)input;
- (void)fitness_getDailyStepSamples:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback;
- (void)fitness_saveSteps:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback;
- (void)fitness_initializeStepEventObserver:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback;

- (void)fitness_registerObserversAtLaunch;
- (void)fitness_enableAllBackgroundObservers;
- (void)fitness_readyToReceiveAllObserverEvents:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback;
- (void)fitness_callObserverCompletionHandler:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback;
// NOTE: Really setAndDoEnableAllBackgroundObservers does not need the input dictionary, neither the callback
- (void)fitness_setAndDoEnableAllBackgroundObservers:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback;
- (void)fitness_initializeStepEventObserverWithBackground:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback;

- (void)fitness_getDistanceWalkingRunningOnDay:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback;
- (void)fitness_getDailyDistanceWalkingRunningSamples:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback;
- (void)fitness_getDistanceCyclingOnDay:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback;
- (void)fitness_getDailyDistanceCyclingSamples:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback;
- (void)fitness_getFlightsClimbedOnDay:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback;
- (void)fitness_getDailyFlightsClimbedSamples:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback;

@end
