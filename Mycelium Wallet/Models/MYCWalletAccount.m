//
//  MYCWalletAccount.m
//  Mycelium Wallet
//
//  Created by Oleg Andreev on 01.10.2014.
//  Copyright (c) 2014 Mycelium. All rights reserved.
//

#import "MYCWallet.h"
#import "MYCWalletAccount.h"

@interface MYCWalletAccount ()
@property(nonatomic) NSTimeInterval syncTimestamp;
@property(nonatomic, readwrite) BTCKeychain* keychain;
@end

@implementation MYCWalletAccount

- (id) initWithKeychain:(BTCKeychain*)keychain
{
    // Sanity check.
    if (!keychain) return nil;
    if (!keychain.isHardened) return nil;

    if (self = [super init])
    {
        _accountIndex = keychain.index;
        _extendedPublicKey = keychain.extendedPublicKey;
        _label = [NSString stringWithFormat:NSLocalizedString(@"Account %@", @""), @(_accountIndex)];
        _keychain = keychain.isPrivate ? keychain.publicKeychain : keychain;
        _syncTimestamp = 0.0;
    }
    return self;
}

- (MYCWallet*) wallet
{
    return [MYCWallet currentWallet];
}

- (BTCKeychain*) keychain
{
    if (!_keychain)
    {
        _keychain = [[BTCKeychain alloc] initWithExtendedKey:_extendedPublicKey];
    }
    return _keychain;
}

- (BTCKeychain*) externalKeychain
{
    return [self.keychain derivedKeychainAtIndex:0 hardened:NO];
}

// Currently available external address to receive payments on.
- (BTCPublicKeyAddress*) externalAddress
{
    NSData* pubkey = [self.keychain externalKeyAtIndex:self.externalKeyIndex].publicKey;
    if (self.wallet.isTestnet)
    {
        return [BTCPublicKeyAddressTestnet addressWithData:BTCHash160(pubkey)];
    }
    return [BTCPublicKeyAddress addressWithData:BTCHash160(pubkey)];
}

// Currently available internal (change) address to receive payments on.
- (BTCPublicKeyAddress*) changeAddress
{
    NSData* pubkey = [self.keychain externalKeyAtIndex:self.internalKeyIndex].publicKey;
    if (self.wallet.isTestnet)
    {
        return [BTCPublicKeyAddressTestnet addressWithData:BTCHash160(pubkey)];
    }
    return [BTCPublicKeyAddress addressWithData:BTCHash160(pubkey)];
}

- (BTCSatoshi) unconfirmedAmount
{
    return self.confirmedAmount + self.pendingChangeAmount + self.pendingReceivedAmount - self.pendingSentAmount;
}

- (BTCSatoshi) spendableAmount
{
    return self.confirmedAmount + self.pendingChangeAmount;
}

- (BTCSatoshi) receivingAmount
{
    return self.pendingReceivedAmount;
}

- (BTCSatoshi) sendingAmount
{
    return self.pendingSentAmount - self.pendingChangeAmount;
}

- (NSDate *) syncDate
{
    if (self.syncTimestamp > 0.0) {
        return [NSDate dateWithTimeIntervalSince1970:self.syncTimestamp];
    } else {
        return nil;
    }
}

- (void)setSyncDate:(NSDate *)syncDate
{
    if (syncDate) {
        self.syncTimestamp = [syncDate timeIntervalSince1970];
    } else {
        self.syncTimestamp = 0.0;
    }
}

// Otherwise MYCDatabaseColumn yields a warning about unrecognized selector.
- (BOOL) archived { return self.isArchived; }
- (BOOL) current { return self.isCurrent; }


#pragma mark - MYCDatabaseRecord


+ (NSString *)tableName
{
    return @"MYCWalletAccounts";
}

+ (NSString *)primaryKeyName
{
    return @"accountIndex";
}

+ (NSArray *)columnNames
{
    return @[MYCDatabaseColumn(accountIndex),
             MYCDatabaseColumn(label),
             MYCDatabaseColumn(extendedPublicKey),
             MYCDatabaseColumn(confirmedAmount),
             MYCDatabaseColumn(pendingChangeAmount),
             MYCDatabaseColumn(pendingReceivedAmount),
             MYCDatabaseColumn(pendingSentAmount),
             MYCDatabaseColumn(archived),
             MYCDatabaseColumn(current),
             MYCDatabaseColumn(externalKeyIndex),
             MYCDatabaseColumn(internalKeyIndex),
             MYCDatabaseColumn(syncTimestamp),
             ];
}

@end
