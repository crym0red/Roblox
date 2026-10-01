#import <UIKit/UIKit.h>
#import "ExecutorKit.h"
#import "ExecutorOverlay.h"

#pragma mark - Small helpers

static UIColor *FEColor(CGFloat r, CGFloat g, CGFloat b, CGFloat a) {
    return [UIColor colorWithRed:r green:g blue:b alpha:a];
}

@interface FEOverlayController : NSObject
@property(nonatomic, strong) UIView *panel;
@property(nonatomic, strong) UITextView *editor;
@property(nonatomic, strong) UITextView *console;
@property(nonatomic, strong) UISegmentedControl *tabs;
@property(nonatomic, strong) NSMutableArray<NSString *> *scripts;
@property(nonatomic, strong) UIWindow *window;
@property(nonatomic, weak) UIGestureRecognizer *gesture;
@property(nonatomic, assign) BOOL visible;
@property(nonatomic, assign) BOOL installed;
- (void)install;
- (void)toggle;
- (void)remove;
- (void)execute;
- (void)clear;
- (void)appendConsole:(NSString *)message;
@end

@implementation FEOverlayController

- (instancetype)init {
    self = [super init];
    if (self) {
        _scripts = [NSMutableArray arrayWithObjects:@"print(\"Hello from ExecutorKit\")", nil];
    }
    return self;
}

- (UIWindow *)activeWindow {
    UIApplication *application = UIApplication.sharedApplication;
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in application.connectedScenes) {
            if (scene.activationState != UISceneActivationStateForegroundActive &&
                scene.activationState != UISceneActivationStateForegroundInactive) {
                continue;
            }
            if (![scene isKindOfClass:[UIWindowScene class]]) continue;
            for (UIWindow *window in ((UIWindowScene *)scene).windows) {
                if (!window.hidden && window.alpha > 0.01 && window.windowLevel == UIWindowLevelNormal) {
                    return window;
                }
            }
        }
    }
    return application.keyWindow;
}

- (void)install {
    if (self.installed) return;

    UIWindow *host = [self activeWindow];
    if (!host) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{ [self install]; });
        return;
    }

    self.window = host;

    UILongPressGestureRecognizer *hold = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(threeFingerHold:)];
    hold.minimumPressDuration = 0.65;
    hold.numberOfTouchesRequired = 3;
    hold.cancelsTouchesInView = NO;
    [host addGestureRecognizer:hold];
    self.gesture = hold;

    [self buildPanelInWindow:host];
    self.installed = YES;
}

- (void)buildPanelInWindow:(UIWindow *)host {
    UIView *panel = [[UIView alloc] initWithFrame:CGRectZero];
    panel.translatesAutoresizingMaskIntoConstraints = NO;
    panel.backgroundColor = FEColor(0.055, 0.055, 0.065, 0.97);
    panel.layer.cornerRadius = 18.0;
    panel.layer.borderWidth = 1.0;
    panel.layer.borderColor = FEColor(1, 1, 1, 0.10).CGColor;
    panel.layer.shadowColor = UIColor.blackColor.CGColor;
    panel.layer.shadowOpacity = 0.35;
    panel.layer.shadowRadius = 24.0;
    panel.layer.shadowOffset = CGSizeMake(0, 12);
    panel.hidden = YES;
    [host addSubview:panel];
    self.panel = panel;

    UILayoutGuide *safe = host.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [panel.centerXAnchor constraintEqualToAnchor:host.centerXAnchor],
        [panel.centerYAnchor constraintEqualToAnchor:host.centerYAnchor],
        [panel.widthAnchor constraintLessThanOrEqualToAnchor:safe.widthAnchor constant:-28.0],
        [panel.widthAnchor constraintEqualToConstant:360.0],
        [panel.heightAnchor constraintLessThanOrEqualToAnchor:safe.heightAnchor constant:-32.0],
        [panel.heightAnchor constraintEqualToConstant:480.0]
    ]];

    UILabel *title = [[UILabel alloc] init];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.text = @"Executor";
    title.textColor = UIColor.whiteColor;
    title.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    [panel addSubview:title];

    UILabel *badge = [[UILabel alloc] init];
    badge.translatesAutoresizingMaskIntoConstraints = NO;
    badge.text = @"LOCAL";
    badge.textColor = FEColor(0.45, 0.85, 1.0, 1);
    badge.font = [UIFont monospacedSystemFontOfSize:10 weight:UIFontWeightBold];
    [panel addSubview:badge];

    self.tabs = [[UISegmentedControl alloc] initWithItems:@[@"Editor", @"Console", @"Library"]];
    self.tabs.translatesAutoresizingMaskIntoConstraints = NO;
    self.tabs.selectedSegmentIndex = 0;
    [self.tabs addTarget:self action:@selector(tabChanged:) forControlEvents:UIControlEventValueChanged];
    [panel addSubview:self.tabs];

    self.editor = [[UITextView alloc] init];
    self.editor.translatesAutoresizingMaskIntoConstraints = NO;
    self.editor.backgroundColor = FEColor(0.02, 0.02, 0.025, 1);
    self.editor.textColor = FEColor(0.92, 0.95, 1, 1);
    self.editor.tintColor = FEColor(0.35, 0.75, 1, 1);
    self.editor.font = [UIFont monospacedSystemFontOfSize:13 weight:UIFontWeightRegular];
    self.editor.layer.cornerRadius = 12;
    self.editor.text = self.scripts.firstObject ?: @"";
    [panel addSubview:self.editor];

    self.console = [[UITextView alloc] init];
    self.console.translatesAutoresizingMaskIntoConstraints = NO;
    self.console.editable = NO;
    self.console.backgroundColor = FEColor(0.02, 0.02, 0.025, 1);
    self.console.textColor = FEColor(0.65, 0.9, 0.72, 1);
    self.console.font = [UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular];
    self.console.layer.cornerRadius = 12;
    self.console.hidden = YES;
    [panel addSubview:self.console];

    UIStackView *buttons = [[UIStackView alloc] init];
    buttons.translatesAutoresizingMaskIntoConstraints = NO;
    buttons.axis = UILayoutConstraintAxisHorizontal;
    buttons.spacing = 10;
    buttons.distribution = UIStackViewDistributionFillEqually;
    [panel addSubview:buttons];

    UIButton *execute = [self buttonWithTitle:@"Execute" action:@selector(execute)];
    UIButton *clear = [self buttonWithTitle:@"Clear" action:@selector(clear)];
    [buttons addArrangedSubview:execute];
    [buttons addArrangedSubview:clear];

    [NSLayoutConstraint activateConstraints:@[
        [title.topAnchor constraintEqualToAnchor:panel.topAnchor constant:16],
        [title.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor constant:18],
        [badge.centerYAnchor constraintEqualToAnchor:title.centerYAnchor],
        [badge.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor constant:-18],
        [tabs.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:12],
        [tabs.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor constant:14],
        [tabs.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor constant:-14],
        [self.editor.topAnchor constraintEqualToAnchor:tabs.bottomAnchor constant:10],
        [self.editor.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor constant:14],
        [self.editor.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor constant:-14],
        [self.editor.bottomAnchor constraintEqualToAnchor:buttons.topAnchor constant:-10],
        [self.console.topAnchor constraintEqualToAnchor:tabs.bottomAnchor constant:10],
        [self.console.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor constant:14],
        [self.console.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor constant:-14],
        [self.console.bottomAnchor constraintEqualToAnchor:buttons.topAnchor constant:-10],
        [buttons.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor constant:14],
        [buttons.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor constant:-14],
        [buttons.bottomAnchor constraintEqualToAnchor:panel.bottomAnchor constant:-14],
        [buttons.heightAnchor constraintEqualToConstant:44]
    ]];

    [self appendConsole:@"> ExecutorKit ready\n> Three-finger hold toggles this panel."];
}

- (UIButton *)buttonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.backgroundColor = FEColor(0.12, 0.13, 0.16, 1);
    button.layer.cornerRadius = 11;
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)threeFingerHold:(UILongPressGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        [self toggle];
    }
}

- (void)toggle {
    if (!self.panel) return;
    self.visible = !self.visible;
    if (self.visible) {
        self.panel.hidden = NO;
        self.panel.alpha = 0;
        self.panel.transform = CGAffineTransformMakeScale(0.96, 0.96);
        [UIView animateWithDuration:0.18 animations:^{
            self.panel.alpha = 1;
            self.panel.transform = CGAffineTransformIdentity;
        }];
    } else {
        [UIView animateWithDuration:0.15 animations:^{
            self.panel.alpha = 0;
            self.panel.transform = CGAffineTransformMakeScale(0.96, 0.96);
        } completion:^(BOOL finished) {
            self.panel.hidden = YES;
            self.panel.transform = CGAffineTransformIdentity;
        }];
    }
}

- (void)tabChanged:(UISegmentedControl *)sender {
    NSInteger index = sender.selectedSegmentIndex;
    self.editor.hidden = index != 0;
    self.console.hidden = index != 1;

    if (index == 2) {
        NSMutableString *library = [NSMutableString stringWithString:@"Saved scripts\n\n"];
        for (NSUInteger i = 0; i < self.scripts.count; i++) {
            [library appendFormat:@"%lu. %@\n", (unsigned long)(i + 1), self.scripts[i]];
        }
        self.console.hidden = NO;
        self.console.text = library;
    } else if (index == 1) {
        self.console.hidden = NO;
    }
}

- (void)execute {
    NSString *script = self.editor.text ?: @"";
    if (script.length == 0) {
        [self appendConsole:@"> Execute skipped: editor is empty."];
        return;
    }

    if (![self.scripts containsObject:script]) {
        [self.scripts insertObject:script atIndex:0];
    }

    int32_t result = FE_ExecuteLocal(script.UTF8String);
    [self appendConsole:[NSString stringWithFormat:@"> Execute returned %d", result]];
}

- (void)clear {
    self.editor.text = @"";
    [self appendConsole:@"> Editor cleared."];
}

- (void)appendConsole:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *existing = self.console.text ?: @"";
        self.console.text = existing.length ? [existing stringByAppendingFormat:@"\n%@", message] : message;
        [self.console scrollRangeToVisible:NSMakeRange(self.console.text.length, 0)];
    });
}

- (void)remove {
    if (self.gesture) {
        [self.window removeGestureRecognizer:self.gesture];
    }
    [self.panel removeFromSuperview];
    self.panel = nil;
    self.gesture = nil;
    self.visible = NO;
    self.installed = NO;
}

@end

static FEOverlayController *gFEOverlay;

void FE_InstallExecutorOverlay(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!gFEOverlay) gFEOverlay = [FEOverlayController new];
        [gFEOverlay install];
    });
}

void FE_RemoveExecutorOverlay(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [gFEOverlay remove];
        gFEOverlay = nil;
    });
}

__attribute__((constructor))
static void FE_OverlayConstructor(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        FE_InstallExecutorOverlay();
    });
}
