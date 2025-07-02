#import "Headers.h"
#import <objc/runtime.h>

@interface LanguageSelector ()
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *languages;
@end

@implementation LanguageSelector

- (void)viewDidLoad {
    [super viewDidLoad];

    NSString *filePath = jbroot(@"/Library/Application Support/TGExtra/TGExtra.bundle/langs.json");
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
		filePath = [NSString stringWithFormat:@"%@/TGExtra.bundle/langs.json", [[NSBundle mainBundle] resourcePath]];
    }

    NSError *jsonDecodeError = nil;
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    NSArray *langs = nil;

    if (data) {
        langs = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonDecodeError];
    }

    if (jsonDecodeError || !langs) {
        self.languages = @[
           @{
               @"name": @"Chinese",
               @"code": @"cn",
               @"flag": @"🇨🇳"
           }
        ];
    } else {
        self.languages = langs;
    }

	self.title = @"🇨🇳刀刀";
	[self loadLanguages];
    [self setupTableView];
}

- (void)setupTableView {
	self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	self.tableView.translatesAutoresizingMaskIntoConstraints = NO;

	[self.view addSubview:self.tableView];

	[NSLayoutConstraint activateConstraints:@[
    	[self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
		[self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
		[self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
		[self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
	]];
}

- (void)loadLanguages {
    NSMutableArray *languages = [NSMutableArray array];

    for (NSDictionary *language in self.languages) {
        NSString *localizationFilePath = [NSString stringWithFormat:@"%@/TGExtra.bundle/%@.lproj/Localizable.strings", jbroot(@"/Library/Application Support/TGExtra"), language[@"code"]];
        BOOL hasFile = [[NSFileManager defaultManager] fileExistsAtPath:localizationFilePath];

        if (!hasFile) {
            localizationFilePath = [NSString stringWithFormat:@"%@/TGExtra.bundle/%@.lproj/Localizable.strings", [[NSBundle mainBundle] resourcePath], language[@"code"]];
            hasFile = (localizationFilePath != nil);
        }

        [languages addObject:@{
            @"code": language[@"code"],
            @"name" : language[@"name"],
            @"flag": language[@"flag"],
            @"path" : localizationFilePath,
            @"isValid" : @(hasFile)}
        ];
    }

    self.languages = [languages copy];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.languages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"languageCell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    } else {
        cell.imageView.image = nil;
        cell.accessoryView = nil;
		cell.alpha = 1.0;
		cell.userInteractionEnabled = YES;
		cell.accessoryType = UITableViewCellAccessoryNone;
    }

    NSDictionary *languageData = self.languages[indexPath.row];

    NSString *title = [NSString stringWithFormat:@"%@ %@", languageData[@"flag"], languageData[@"name"]];
    cell.textLabel.text = title;

    if (![languageData[@"isValid"] boolValue]) {
        cell.alpha = 0.6;
        cell.userInteractionEnabled = NO;
    }
    NSString *selectedLanguageCode = [[NSUserDefaults standardUserDefaults] stringForKey:@"TGExtraLanguage"];

    if ([selectedLanguageCode isEqualToString:languageData[@"code"]]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *languageData = self.languages[indexPath.row];

    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:languageData[@"path"]];

    if (!dict) {
        [self showAlertWithTitle:@"错误" message:@"无法加载本地化语言数据"];
        return;
    }

    TGLocalization *localization = [[objc_getClass("TGLocalization") alloc] initWithVersion:96929692
                                                                   code:languageData[@"code"]
                                                                   dict:dict
                                                              isActive:YES];

    if (localization) {
        [TGExtraLocalization shared].localization = localization;

        [[NSUserDefaults standardUserDefaults] setObject:languageData[@"code"] forKey:@"TGExtraLanguage"];
        [[NSUserDefaults standardUserDefaults] synchronize];

        [[NSNotificationCenter defaultCenter] postNotificationName:@"LanguageChangedNotification" object:nil];

        [tableView deselectRowAtIndexPath:indexPath animated:YES];

        [tableView reloadData];
    } else {
        [self showAlertWithTitle:@"错误" message:@"无法加载语言"];
    }
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"好的"
                                                       style:UIAlertActionStyleDefault
                                                     handler:nil];

    [alert addAction:okAction];

    [self presentViewController:alert animated:YES completion:nil];
}

@end
