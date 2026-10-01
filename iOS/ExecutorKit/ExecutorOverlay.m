#import <UIKit/UIKit.h>
#import "ExecutorKit.h"
#import "ExecutorOverlay.h"

#pragma mark - Palette

static UIColor *FEColor(CGFloat r, CGFloat g, CGFloat b, CGFloat a) {
    return [UIColor colorWithRed:r green:g blue:b alpha:a];
}

static UIColor *FEPanelColor(void) { return FEColor(0.035, 0.038, 0.045, 0.985); }
static UIColor *FEBarColor(void)   { return FEColor(0.045, 0.047, 0.055, 0.98); }
static UIColor *FESurface(void)     { return FEColor(0.065, 0.068, 0.078, 1.0); }
static UIColor *FEEditor(void)      { return FEColor(0.018, 0.020, 0.025, 1.0); }
static UIColor *FEAccent(void)      { return FEColor(0.15, 0.82, 0.42, 1.0); }

@interface FEOverlayController : NSObject
@property(nonatomic, strong) UIView *panel;
@property(nonatomic, strong) UIView *sidebar;
@property(nonatomic, strong) UIView *content;
@property(nonatomic, strong) UITextView *editor;
@property(nonatomic, strong) UITextView *console;
@property(nonatomic, strong) UISegmentedControl *tabs;
@property(nonatomic, strong) NSMutableArray<NSString *> *scripts;
@property(nonatomic, strong) UIWindow *window;
@property(nonatomic, weak) UIGestureRecognizer *gesture;
@property(nonatomic, strong) UIPinchGestureRecognizer *pinch;
@property(nonatomic, strong) NSLayoutConstraint *panelWidth;
@property(nonatomic, strong) NSLayoutConstraint *panelHeight;
@property(nonatomic, strong) UIButton *executeButton;
@property(nonatomic, strong) UIButton *clearButton;
@property(nonatomic, strong) UILabel *statusLabel;
@property(nonatomic, assign) BOOL visible;
@property(nonatomic, assign) BOOL installed;
@property(nonatomic, assign) CGFloat pinchStartWidth;
@property(nonatomic, assign) CGFloat pinchStartHeight;
@property(nonatomic, assign) BOOL maximized;
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
        _scripts = [NSMutableArray arrayWithObject:@"print(\"Hello from ExecutorKit\")"];
    }
    return self;
}

- (UIWindow *)activeWindow {
    UIApplication *application = UIApplication.sharedApplication;
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in application.connectedScenes) {
            if (scene.activationState != UISceneActivationStateForegroundActive &&
                scene.activationState != UISceneActivationStateForegroundInactive) continue;
            if (![scene isKindOfClass:[UIWindowScene class]]) continue;
            for (UIWindow *window in ((UIWindowScene *)scene).windows) {
                if (!window.hidden && window.alpha > 0.01 && window.windowLevel == UIWindowLevelNormal) return window;
            }
        }
    }
    return application.keyWindow;
}

- (void)install {
    if (self.installed) return;
    UIWindow *host = [self activeWindow];
    if (!host) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self install];
        });
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
    panel.backgroundColor = FEPanelColor();
    panel.layer.cornerRadius = 22.0;
    panel.layer.borderWidth = 1.0;
    panel.layer.borderColor = FEColor(1, 1, 1, 0.11).CGColor;
    panel.layer.shadowColor = UIColor.blackColor.CGColor;
    panel.layer.shadowOpacity = 0.45;
    panel.layer.shadowRadius = 28.0;
    panel.layer.shadowOffset = CGSizeMake(0, 16);
    panel.hidden = YES;
    panel.clipsToBounds = YES;
    [host addSubview:panel];
    self.panel = panel;

    UILayoutGuide *safe = host.safeAreaLayoutGuide;
    self.panelWidth = [panel.widthAnchor constraintEqualToConstant:MIN(900.0, MAX(340.0, host.bounds.size.width - 28.0))];
    self.panelHeight = [panel.heightAnchor constraintEqualToConstant:MIN(620.0, MAX(300.0, host.bounds.size.height - 40.0))];
    [NSLayoutConstraint activateConstraints:@[
        [panel.centerXAnchor constraintEqualToAnchor:host.centerXAnchor],
        [panel.centerYAnchor constraintEqualToAnchor:host.centerYAnchor],
        [panel.widthAnchor constraintLessThanOrEqualToAnchor:safe.widthAnchor constant:-20],
        [panel.heightAnchor constraintLessThanOrEqualToAnchor:safe.heightAnchor constant:-20],
        self.panelWidth,
        self.panelHeight
    ]];

    UIView *topbar = [[UIView alloc] init];
    topbar.translatesAutoresizingMaskIntoConstraints = NO;
    topbar.backgroundColor = FEBarColor();
    [panel addSubview:topbar];

    UILabel *logo = [[UILabel alloc] init];
    logo.translatesAutoresizingMaskIntoConstraints = NO;
    logo.text = @"◉";
    logo.textColor = UIColor.whiteColor;
    logo.font = [UIFont systemFontOfSize:24 weight:UIFontWeightBold];
    [topbar addSubview:logo];

    UILabel *title = [[UILabel alloc] init];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.text = @"TrustC0re";
    title.textColor = UIColor.whiteColor;
    title.font = [UIFont systemFontOfSize:19 weight:UIFontWeightSemibold];
    [topbar addSubview:title];

    UIView *statusDot = [[UIView alloc] init];
    statusDot.translatesAutoresizingMaskIntoConstraints = NO;
    statusDot.backgroundColor = FEAccent();
    statusDot.layer.cornerRadius = 5;
    [topbar addSubview:statusDot];

    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusLabel.text = @"Ready";
    self.statusLabel.textColor = FEAccent();
    self.statusLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    [topbar addSubview:self.statusLabel];

    UIButton *minimize = [self topButton:@"−" action:@selector(minimizePanel)];
    UIButton *maximize = [self topButton:@"↗" action:@selector(maximizePanel)];
    UIButton *close = [self topButton:@"×" action:@selector(toggle)];
    [topbar addSubview:minimize]; [topbar addSubview:maximize]; [topbar addSubview:close];

    UIView *handle = [[UIView alloc] init];
    handle.translatesAutoresizingMaskIntoConstraints = NO;
    handle.backgroundColor = FEColor(1,1,1,0.16);
    handle.layer.cornerRadius = 3;
    [topbar addSubview:handle];

    UIView *sidebar = [[UIView alloc] init];
    sidebar.translatesAutoresizingMaskIntoConstraints = NO;
    sidebar.backgroundColor = FEColor(0.048, 0.050, 0.058, 1);
    [panel addSubview:sidebar];
    self.sidebar = sidebar;

    UIButton *home = [self sidebarButton:@"⌂" title:@"Home" selected:YES action:@selector(sidebarHome:)];
    UIButton *scripts = [self sidebarButton:@"‹›" title:@"Scripts" selected:NO action:@selector(sidebarScripts:)];
    UIButton *library = [self sidebarButton:@"□" title:@"Library" selected:NO action:@selector(sidebarLibrary:)];
    UIButton *console = [self sidebarButton:@"▢" title:@"Console" selected:NO action:@selector(sidebarConsole:)];
    UIButton *settings = [self sidebarButton:@"⚙" title:@"Settings" selected:NO action:@selector(sidebarSettings:)];
    UIButton *profile = [self sidebarButton:@"♙" title:@"Profile" selected:NO action:@selector(sidebarProfile:)];
    UIStackView *nav = [[UIStackView alloc] initWithArrangedSubviews:@[home, scripts, library, console]];
    nav.translatesAutoresizingMaskIntoConstraints = NO;
    nav.axis = UILayoutConstraintAxisVertical;
    nav.spacing = 6;
    [sidebar addSubview:nav];
    [sidebar addSubview:settings]; [sidebar addSubview:profile];

    UIView *content = [[UIView alloc] init];
    content.translatesAutoresizingMaskIntoConstraints = NO;
    content.backgroundColor = FEPanelColor();
    [panel addSubview:content];
    self.content = content;

    self.tabs = [[UISegmentedControl alloc] initWithItems:@[@"New Script", @"Welcome Back", @"+"]];
    self.tabs.translatesAutoresizingMaskIntoConstraints = NO;
    self.tabs.selectedSegmentIndex = 0;
    [self.tabs addTarget:self action:@selector(tabChanged:) forControlEvents:UIControlEventValueChanged];
    [content addSubview:self.tabs];

    self.editor = [[UITextView alloc] init];
    self.editor.translatesAutoresizingMaskIntoConstraints = NO;
    self.editor.backgroundColor = FEEditor();
    self.editor.textColor = FEColor(0.90,0.94,1,1);
    self.editor.tintColor = FEAccent();
    self.editor.font = [UIFont monospacedSystemFontOfSize:14 weight:UIFontWeightRegular];
    self.editor.layer.cornerRadius = 10;
    self.editor.layer.borderWidth = 1;
    self.editor.layer.borderColor = FEColor(1,1,1,0.07).CGColor;
    self.editor.text = self.scripts.firstObject ?: @"";
    [content addSubview:self.editor];

    self.console = [[UITextView alloc] init];
    self.console.translatesAutoresizingMaskIntoConstraints = NO;
    self.console.editable = NO;
    self.console.backgroundColor = FEEditor();
    self.console.textColor = FEColor(0.75,0.92,0.80,1);
    self.console.font = [UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular];
    self.console.layer.cornerRadius = 10;
    self.console.layer.borderWidth = 1;
    self.console.layer.borderColor = FEColor(1,1,1,0.07).CGColor;
    self.console.hidden = NO;
    [content addSubview:self.console];

    UILabel *consoleTitle = [[UILabel alloc] init];
    consoleTitle.translatesAutoresizingMaskIntoConstraints = NO;
    consoleTitle.text = @"Console";
    consoleTitle.textColor = UIColor.whiteColor;
    consoleTitle.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    [content addSubview:consoleTitle];

    self.executeButton = [self actionButton:@"▷  Execute" primary:YES action:@selector(execute)];
    self.clearButton = [self actionButton:@"▱  Clear" primary:NO action:@selector(clear)];
    [content addSubview:self.executeButton]; [content addSubview:self.clearButton];

    UILabel *resizeHint = [[UILabel alloc] init];
    resizeHint.translatesAutoresizingMaskIntoConstraints = NO;
    resizeHint.text = @"↔  Pinch to resize";
    resizeHint.textColor = FEColor(0.55,0.57,0.63,1);
    resizeHint.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    [content addSubview:resizeHint];

    self.pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    [panel addGestureRecognizer:self.pinch];

    [NSLayoutConstraint activateConstraints:@[
        [topbar.topAnchor constraintEqualToAnchor:panel.topAnchor], [topbar.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor],
        [topbar.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor], [topbar.heightAnchor constraintEqualToConstant:58],
        [logo.leadingAnchor constraintEqualToAnchor:topbar.leadingAnchor constant:18], [logo.centerYAnchor constraintEqualToAnchor:topbar.centerYAnchor],
        [title.leadingAnchor constraintEqualToAnchor:logo.trailingAnchor constant:12], [title.centerYAnchor constraintEqualToAnchor:topbar.centerYAnchor],
        [statusDot.leadingAnchor constraintEqualToAnchor:title.trailingAnchor constant:22], [statusDot.centerYAnchor constraintEqualToAnchor:topbar.centerYAnchor], [statusDot.widthAnchor constraintEqualToConstant:10], [statusDot.heightAnchor constraintEqualToConstant:10],
        [self.statusLabel.leadingAnchor constraintEqualToAnchor:statusDot.trailingAnchor constant:7], [self.statusLabel.centerYAnchor constraintEqualToAnchor:topbar.centerYAnchor],
        [close.trailingAnchor constraintEqualToAnchor:topbar.trailingAnchor constant:-12], [close.centerYAnchor constraintEqualToAnchor:topbar.centerYAnchor], [close.widthAnchor constraintEqualToConstant:38], [close.heightAnchor constraintEqualToConstant:38],
        [maximize.trailingAnchor constraintEqualToAnchor:close.leadingAnchor constant:-2], [maximize.centerYAnchor constraintEqualToAnchor:topbar.centerYAnchor], [maximize.widthAnchor constraintEqualToConstant:38], [maximize.heightAnchor constraintEqualToConstant:38],
        [minimize.trailingAnchor constraintEqualToAnchor:maximize.leadingAnchor constant:-2], [minimize.centerYAnchor constraintEqualToAnchor:topbar.centerYAnchor], [minimize.widthAnchor constraintEqualToConstant:38], [minimize.heightAnchor constraintEqualToConstant:38],
        [handle.centerXAnchor constraintEqualToAnchor:topbar.centerXAnchor], [handle.bottomAnchor constraintEqualToAnchor:topbar.bottomAnchor constant:-6], [handle.widthAnchor constraintEqualToConstant:74], [handle.heightAnchor constraintEqualToConstant:5],

        [sidebar.topAnchor constraintEqualToAnchor:topbar.bottomAnchor], [sidebar.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor], [sidebar.bottomAnchor constraintEqualToAnchor:panel.bottomAnchor], [sidebar.widthAnchor constraintEqualToConstant:88],
        [nav.topAnchor constraintEqualToAnchor:sidebar.topAnchor constant:10], [nav.leadingAnchor constraintEqualToAnchor:sidebar.leadingAnchor constant:6], [nav.trailingAnchor constraintEqualToAnchor:sidebar.trailingAnchor constant:-6],
        [settings.leadingAnchor constraintEqualToAnchor:sidebar.leadingAnchor constant:6], [settings.trailingAnchor constraintEqualToAnchor:sidebar.trailingAnchor constant:-6], [settings.bottomAnchor constraintEqualToAnchor:profile.topAnchor constant:-4],
        [profile.leadingAnchor constraintEqualToAnchor:sidebar.leadingAnchor constant:6], [profile.trailingAnchor constraintEqualToAnchor:sidebar.trailingAnchor constant:-6], [profile.bottomAnchor constraintEqualToAnchor:sidebar.bottomAnchor constant:-8],

        [content.topAnchor constraintEqualToAnchor:topbar.bottomAnchor], [content.leadingAnchor constraintEqualToAnchor:sidebar.trailingAnchor], [content.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor], [content.bottomAnchor constraintEqualToAnchor:panel.bottomAnchor],
        [self.tabs.topAnchor constraintEqualToAnchor:content.topAnchor constant:8], [self.tabs.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:10], [self.tabs.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-10], [self.tabs.heightAnchor constraintEqualToConstant:34],
        [self.editor.topAnchor constraintEqualToAnchor:self.tabs.bottomAnchor constant:8], [self.editor.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:10], [self.editor.trailingAnchor constraintEqualToAnchor:consoleTitle.leadingAnchor constant:-10], [self.editor.bottomAnchor constraintEqualToAnchor:self.executeButton.topAnchor constant:-12],
        [consoleTitle.topAnchor constraintEqualToAnchor:self.tabs.bottomAnchor constant:18], [consoleTitle.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-14], [consoleTitle.widthAnchor constraintEqualToConstant:112],
        [self.console.topAnchor constraintEqualToAnchor:consoleTitle.bottomAnchor constant:7], [self.console.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-10], [self.console.widthAnchor constraintEqualToConstant:112], [self.console.bottomAnchor constraintEqualToAnchor:self.executeButton.topAnchor constant:-12],
        [self.executeButton.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:14], [self.executeButton.bottomAnchor constraintEqualToAnchor:content.bottomAnchor constant:-12], [self.executeButton.widthAnchor constraintEqualToConstant:150], [self.executeButton.heightAnchor constraintEqualToConstant:42],
        [self.clearButton.leadingAnchor constraintEqualToAnchor:self.executeButton.trailingAnchor constant:10], [self.clearButton.bottomAnchor constraintEqualToAnchor:content.bottomAnchor constant:-12], [self.clearButton.widthAnchor constraintEqualToConstant:130], [self.clearButton.heightAnchor constraintEqualToConstant:42],
        [resizeHint.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-16], [resizeHint.centerYAnchor constraintEqualToAnchor:self.executeButton.centerYAnchor]
    ]];

    [self appendConsole:@"[+] TrustC0re ready\n[+] Three-finger hold toggles panel\n[+] Two-finger pinch resizes panel"];
}

- (UIButton *)topButton:(NSString *)title action:(SEL)action {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    [b setTitle:title forState:UIControlStateNormal];
    [b setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightRegular];
    [b addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return b;
}

- (UIButton *)sidebarButton:(NSString *)symbol title:(NSString *)title selected:(BOOL)selected action:(SEL)action {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    b.translatesAutoresizingMaskIntoConstraints = NO;
    b.accessibilityLabel = title;
    [b setTitle:[NSString stringWithFormat:@"%@\n%@", symbol, title] forState:UIControlStateNormal];
    [b setTitleColor:selected ? UIColor.whiteColor : FEColor(0.78,0.80,0.84,1) forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont systemFontOfSize:12 weight:selected ? UIFontWeightSemibold : UIFontWeightRegular];
    b.titleLabel.numberOfLines = 2;
    b.titleLabel.textAlignment = NSTextAlignmentCenter;
    b.backgroundColor = selected ? FEColor(0.55,0.05,0.09,0.92) : UIColor.clearColor;
    b.layer.cornerRadius = 10;
    b.contentEdgeInsets = UIEdgeInsetsMake(8, 2, 8, 2);
    [b addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [b.heightAnchor constraintEqualToConstant:62].active = YES;
    return b;
}

- (UIButton *)actionButton:(NSString *)title primary:(BOOL)primary action:(SEL)action {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    b.translatesAutoresizingMaskIntoConstraints = NO;
    b.backgroundColor = primary ? FEAccent() : FEColor(0.10,0.12,0.15,1);
    b.layer.cornerRadius = 12;
    [b setTitle:title forState:UIControlStateNormal];
    [b setTitleColor:primary ? UIColor.blackColor : UIColor.whiteColor forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    [b addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return b;
}

- (void)threeFingerHold:(UILongPressGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) [self toggle];
}

- (void)toggle {
    if (!self.panel) return;
    self.visible = !self.visible;
    if (self.visible) {
        self.panel.hidden = NO;
        self.panel.alpha = 0;
        self.panel.transform = CGAffineTransformMakeScale(0.96, 0.96);
        [UIView animateWithDuration:0.18 animations:^{ self.panel.alpha = 1; self.panel.transform = CGAffineTransformIdentity; }];
    } else {
        [UIView animateWithDuration:0.15 animations:^{ self.panel.alpha = 0; self.panel.transform = CGAffineTransformMakeScale(0.96, 0.96); } completion:^(BOOL finished) {
            self.panel.hidden = YES; self.panel.transform = CGAffineTransformIdentity;
        }];
    }
}

- (void)handlePinch:(UIPinchGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        self.pinchStartWidth = self.panelWidth.constant;
        self.pinchStartHeight = self.panelHeight.constant;
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        CGFloat scale = gesture.scale;
        CGFloat w = MIN(self.window.bounds.size.width - 20.0, MAX(300.0, self.pinchStartWidth * scale));
        CGFloat h = MIN(self.window.bounds.size.height - 20.0, MAX(250.0, self.pinchStartHeight * scale));
        self.panelWidth.constant = w;
        self.panelHeight.constant = h;
        [self.panel.superview layoutIfNeeded];
    } else if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled) {
        self.maximized = self.panelWidth.constant > self.window.bounds.size.width * 0.82;
    }
}

- (void)minimizePanel {
    self.panelWidth.constant = MIN(430.0, self.window.bounds.size.width - 24.0);
    self.panelHeight.constant = MIN(330.0, self.window.bounds.size.height - 32.0);
    [UIView animateWithDuration:0.2 animations:^{ [self.panel.superview layoutIfNeeded]; }];
    self.maximized = NO;
}

- (void)maximizePanel {
    self.panelWidth.constant = self.window.bounds.size.width - 20.0;
    self.panelHeight.constant = self.window.bounds.size.height - 20.0;
    [UIView animateWithDuration:0.2 animations:^{ [self.panel.superview layoutIfNeeded]; }];
    self.maximized = YES;
}

- (void)tabChanged:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 2) {
        NSMutableString *library = [NSMutableString stringWithString:@"Saved scripts\n\n"];
        for (NSUInteger i = 0; i < self.scripts.count; i++) [library appendFormat:@"%lu. %@\n", (unsigned long)(i + 1), self.scripts[i]];
        self.editor.text = library;
    } else if (sender.selectedSegmentIndex == 1) {
        [self appendConsole:@"[console] Ready."];
    }
}

- (void)sidebarHome:(id)sender { self.tabs.selectedSegmentIndex = 0; self.editor.hidden = NO; }
- (void)sidebarScripts:(id)sender { self.tabs.selectedSegmentIndex = 0; self.editor.hidden = NO; }
- (void)sidebarLibrary:(id)sender { self.tabs.selectedSegmentIndex = 2; [self tabChanged:self.tabs]; }
- (void)sidebarConsole:(id)sender { [self appendConsole:@"[console] Ready."]; }
- (void)sidebarSettings:(id)sender { [self appendConsole:@"[settings] Local TrustC0re settings."]; }
- (void)sidebarProfile:(id)sender { [self appendConsole:@"[profile] Local runtime."]; }

- (void)execute {
    NSString *script = self.editor.text ?: @"";
    if (!script.length) { [self appendConsole:@"> Execute skipped: editor is empty."]; return; }
    if (![self.scripts containsObject:script]) [self.scripts insertObject:script atIndex:0];
    self.statusLabel.text = @"Running";
    int32_t result = FE_ExecuteLocal(script.UTF8String);
    self.statusLabel.text = result == 0 ? @"Ready" : @"Error";
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
    if (self.gesture) [self.window removeGestureRecognizer:self.gesture];
    if (self.panel) [self.panel removeFromSuperview];
    self.panel = nil; self.gesture = nil; self.pinch = nil;
    self.visible = NO; self.installed = NO;
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
    dispatch_async(dispatch_get_main_queue(), ^{ FE_InstallExecutorOverlay(); });
}
