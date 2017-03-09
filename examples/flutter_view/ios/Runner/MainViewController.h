// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MainViewController_h
#define MainViewController_h

#endif /* MainViewController_h */

#import <UIKit/UIKit.h>
#import <Flutter/Flutter.h>
#import "NativeViewController.h"

@protocol NativeViewControllerDelegate;

@interface MainViewController : UIViewController <FlutterMessageListener,
                                                  NativeViewControllerDelegate>
@end

