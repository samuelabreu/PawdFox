//
//  wrapper.m
//  PawdFox
//
//  Created by samuel.abreu on 11/01/2018.
//  Copyright © 2018 Personal Project. All rights reserved.
//

#import "wrapper.h"
#include "libpawdfox.h"

@implementation Credential

@synthesize site;
@synthesize username;
@synthesize encryptedPassword;

@end

@implementation WrapperClass {
    libpawdfox::PawdFox pfox;
    libpawdfox::firefox_profile profile;
}

- (int)openIni {
    pfox = libpawdfox::PawdFox();
    return pfox.OpenIni();
}

- (int)openIni:(NSString*)path {
    pfox = libpawdfox::PawdFox();
    return pfox.OpenIni([path UTF8String]);
}

- (unsigned long)profileSize {
    return pfox.profiles.size();
}

- (int) readLogins:(int)index {
    return [self readLogins:index withPassword:@""];
}

- (int) readLogins:(int)index withPassword:(NSString*)password {
    if (index <= self.profileSize) {
        profile = pfox.profiles[index];
        profile.password = [password UTF8String];
        int status = pfox.ReadLogins(profile);
        return status;
    }
    return -1;
}

- (NSArray*) profiles {
    NSMutableArray *ret = [NSMutableArray new];
    for (int i = 0; i < self.profileSize; i++) {
        NSString* path = [NSString stringWithUTF8String:pfox.profiles[i].name.c_str()];
        [ret addObject: path];
    }
    return ret;
}

- (NSArray*) credentials {
    NSMutableArray *ret = [NSMutableArray new];
    for (int i = 0; i < pfox.credentials.size(); i++) {
        Credential *c = [Credential new];
        c.site = [NSString stringWithUTF8String:pfox.credentials[i].hostname.c_str()];
        c.username = [NSString stringWithUTF8String:pfox.credentials[i].username.c_str()];
        c.encryptedPassword = [NSString stringWithUTF8String:pfox.credentials[i].encrypted_password.c_str()];
        [ret addObject: c];
    }
    return ret;
}

- (int) closeProfile {
    return pfox.CloseProfile();
}

- (NSArray*) filter:(NSString*)query {
    NSMutableArray *ret = [NSMutableArray new];
    std::vector<libpawdfox::firefox_credential> creds = pfox.Filter([query UTF8String]);
    for (int i = 0; i < creds.size(); i++) {
        Credential *c = [Credential new];
        c.site = [NSString stringWithUTF8String:creds[i].hostname.c_str()];
        c.username = [NSString stringWithUTF8String:creds[i].username.c_str()];
        c.encryptedPassword = [NSString stringWithUTF8String:creds[i].encrypted_password.c_str()];
        [ret addObject: c];
    }
    return ret;
}

- (NSString*) decryptPassword: (NSString*)password {
    NSString* ret = password;
    try {
        std::string stdret = pfox.GetPassword([password UTF8String]);
        ret = [NSString stringWithUTF8String:stdret.c_str()];
    }
    catch(...) {
        ret = nil;
    }
    return ret;
}

@end
