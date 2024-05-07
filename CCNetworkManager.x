#import "CCNetworkManager.h"

NSMutableDictionary *prefs, *defaultPrefs;
// For some reason if I declare the 3 values below as simple NSDictionaries/NSArray, they just crash w BAD_ACCESS
// When I call anything on them. Making them mutable fixes this.
NSMutableDictionary *ratSelectionValues, *labelSelectionValues;
NSMutableArray* selectionKeys;

NSString *selectedNetwork;

@implementation CCNetworkManager

- (UIImage *)iconGlyph {
  UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 70, 70)];
  label.textColor = [UIColor blackColor];
  label.backgroundColor = [UIColor clearColor];
  label.baselineAdjustment = UIBaselineAdjustmentAlignBaselines;
  label.adjustsFontSizeToFitWidth = YES;
  label.minimumScaleFactor = 10.0f / 12.0f;
  label.clipsToBounds = YES;
  label.textAlignment = NSTextAlignmentCenter;

  if ([selectedNetwork isEqual:@"disabled"]) {
    label.font = [label.font fontWithSize:12];

    NSString *customText =
        getValue(@"customText") ? getValue(@"customText") : @"";

    if ([customText length] > 0) {
      // String contains space that should be converted to linebreak
      if ([customText rangeOfString:@" "].location != NSNotFound) {
        label.numberOfLines = 2;
        customText = [customText stringByReplacingOccurrencesOfString:@" "
                                                           withString:@"\n"];
      } else {
        label.numberOfLines = 1;
      }
      label.text = customText;
    } else {
      label.numberOfLines = 2;
      label.text = @"Auto\nNetwork";
    }

  } else {
    label.font = [label.font fontWithSize:15];
    label.numberOfLines = 1;

    label.text = [labelSelectionValues objectForKey:selectedNetwork];
  }

  UIGraphicsBeginImageContextWithOptions(label.bounds.size, NO, 0.0); // high res
  [[label layer] renderInContext:UIGraphicsGetCurrentContext()];
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  return image;
}

- (UIColor *)selectedColor {
  return [UIColor colorWithRed:1.00 green:0.58 blue:0.00 alpha:1.0];
}

- (BOOL)isSelected {
  return ![selectedNetwork isEqual:@"disabled"];
}

- (void)setSelected:(BOOL)selected {
  selectedNetwork = getNextEnabledNetwork();

  CFStringRef kValue = (__bridge CFStringRef)[ratSelectionValues objectForKey:selectedNetwork];
  CTServerConnectionRef cn = _CTServerConnectionCreate(kCFAllocatorDefault, callback, NULL);
  _CTServerConnectionSetRATSelection(cn, kValue, 0);

  writeSelectedNetwork();
  [super reconfigureView];
}

@end

// ----- UTILS ----- //
static void sendSimpleAlert(NSString *title, NSString *content) {
  UIAlertController *alertController =
      [UIAlertController alertControllerWithTitle:title
                                          message:content
                                   preferredStyle:UIAlertControllerStyleAlert];

  UIAlertAction *okAction =
      [UIAlertAction actionWithTitle:@"Ok"
                               style:UIAlertActionStyleDefault
                             handler:nil];

  [alertController addAction:okAction];

  UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
  [keyWindow.rootViewController presentViewController:alertController
                                             animated:YES
                                           completion:nil];
}

static NSString *getNextEnabledNetwork() {
    // TODO: CHECK INPUT VALUE
    NSUInteger index = [selectionKeys indexOfObject:selectedNetwork];
    NSUInteger count = [selectionKeys count];

    // Loop through the keys starting from the index+1 of the current network
    for (NSUInteger i = index+1; i < count; i++) {
        NSString *key = selectionKeys[i];
        BOOL isEnabled = getBool(key);
        if (isEnabled) {
            return key;
        }
    }
    // If no enabled network is found after the current network back to index 0 (which is "disabled" & always on)
    return @"disabled";
}

// ----- PREFERENCES ----- //

static BOOL getBool(NSString *key) {
  id ret = [prefs objectForKey:key];

  if (ret == nil) {
    ret = [defaultPrefs objectForKey:key];
  }

  return [ret boolValue];
}

static NSString *getValue(NSString *key) {
  return [prefs objectForKey:key] ?: [defaultPrefs objectForKey:key];
}

static void writeSelectedNetwork() {
  [prefs setObject:selectedNetwork forKey:@"selectedNetwork"];
  [prefs writeToFile:
             ROOT_PATH_NS(@"/User/Library/Preferences/me.nixuge.networkmanager.plist")
          atomically:YES];
}

// ----- INIT ----- //

static void loadPrefs() {
  prefs = [[NSMutableDictionary alloc]
      initWithContentsOfFile:ROOT_PATH_NS(@"/var/mobile/Library/Preferences/"
                             @"me.nixuge.networkmanager.plist")];
  selectedNetwork = [[prefs objectForKey:@"selectedNetwork"]?: [defaultPrefs objectForKey:@"selectedNetwork"] stringValue];
}

static void initPrefs() {
  // Copy the default preferences file when the actual preference file doesn't
  // exist
  NSString *path =
      ROOT_PATH_NS(@"/User/Library/Preferences/me.nixuge.networkmanager.plist");
  NSString *pathDefault =
      ROOT_PATH_NS(@"/Library/PreferenceBundles/NetworkManagerPrefs.bundle/defaults.plist");
  NSFileManager *fileManager = [NSFileManager defaultManager];
  if (![fileManager fileExistsAtPath:path]) {
    [fileManager copyItemAtPath:pathDefault toPath:path error:nil];
  }

  defaultPrefs =
      [[NSMutableDictionary alloc] initWithContentsOfFile:pathDefault];

  CFNotificationCenterAddObserver(
      CFNotificationCenterGetDarwinNotifyCenter(), NULL,
      (CFNotificationCallback)loadPrefs,
      CFSTR("me.nixuge.networkmanager/prefsupdated"), NULL,
      CFNotificationSuspensionBehaviorCoalesce);
}

static void initDataValues() {
    // Unfortunately dicts are not ordered in objc, so i have to make an array w the keys in order here
    selectionKeys = [@[
      @"disabled",
      @"enable2gGSM",
      @"enable3gGSM",
      @"enable2gCDMA",
      @"enable3gCDMA",
      @"enableLTE",
      @"enable5gNRStandAlone",
      @"enable5gNRNonStandAlone",
      @"enable5gNR"
    ] mutableCopy];

    ratSelectionValues = [@{
      @"disabled" : (__bridge id)kAutomatic,
      @"enable2gGSM" : (__bridge id)kGSM,
      @"enable3gGSM" : (__bridge id)kUMTS,
      @"enable2gCDMA" : (__bridge id)kCDMA,
      @"enable3gCDMA" : (__bridge id)kEVDO,
      @"enableLTE" : (__bridge id)kLTE,
      @"enable5gNRStandAlone" : (__bridge id)kNRStandAlone,
      @"enable5gNRNonStandAlone" : (__bridge id)kNRNonStandAlone,
      @"enable5gNR" : (__bridge id)kNR
    } mutableCopy];

    labelSelectionValues = [@{
      @"disabled" : @"Auto",
      @"enable2gGSM" : @"2G (GSM)",
      @"enable3gGSM" : @"3G (GSM)",
      @"enable2gCDMA" : @"2G (CDMA)",
      @"enable3gCDMA" : @"3G (CDMA)",
      @"enableLTE" : @"LTE",
      @"enable5gNRStandAlone" : @"5G (SA)",
      @"enable5gNRNonStandAlone" : @"5G (NSA)",
      @"enable5gNR" : @"5G"
    } mutableCopy];
  }

%ctor {
  initDataValues();
  initPrefs();
  loadPrefs();
}
