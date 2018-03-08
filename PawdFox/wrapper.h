//
//  wrapper.h
//  PawdFox
//
//  Created by samuel.abreu on 11/01/2018.
//  Copyright © 2018 Personal Project. All rights reserved.
//

#ifndef wrapper_h
#import <Foundation/Foundation.h>

@interface Credential: NSObject
@property NSString *site;
@property NSString *username;
@property NSString *encryptedPassword;
@end

@interface WrapperClass: NSObject

- (int) openIni;
- (int)openIni:(NSString*)path;
- (unsigned long) profileSize;
- (int) readLogins:(int)index;
- (int) readLogins:(int)index withPassword:(NSString*)password;
- (NSArray*) profiles;
- (NSArray*) credentials;
- (int) closeProfile;
- (NSArray*) filter:(NSString*)query;
- (NSString*) decryptPassword: (NSString*)password;
@end

#define wrapper_h


#endif /* wrapper_h */
