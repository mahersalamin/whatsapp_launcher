import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'database_helper.dart';
import 'banner_ad_widget.dart';

final TextEditingController _controller = TextEditingController();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(MobileAds.instance.initialize());
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;
  static const platform = MethodChannel('com.code_nest.whatsapp_launcher/share');
  @override
  void initState() {
    super.initState();
    platform.setMethodCallHandler(_handleIncomingShare);
  }
  Future<void> _handleIncomingShare(MethodCall call) async {
    if (call.method == "sharedText") {
      setState(() {
        _controller.text = call.arguments as String;
      });
    }
  }
  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.blue,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.teal,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
      ),
      themeMode: _themeMode,
      home: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('WhatsApp Launcher'),
          actions: [
            IconButton(
              icon: Icon(
                _themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
              ),
              onPressed: _toggleTheme,
            ),
          ],
        ),
        body: const WhatsAppLauncher(),
        bottomNavigationBar: const BannerAdWidget(),
      ),
    );
  }
}

class WhatsAppLauncher extends StatefulWidget {
  const WhatsAppLauncher({super.key});

  @override
  _WhatsAppLauncherState createState() => _WhatsAppLauncherState();
}

class _WhatsAppLauncherState extends State<WhatsAppLauncher> {
  String? _errorText;
  bool _isLoading = false;
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<ContactModel> _contacts = [];

  void _launchWhatsApp(String number) async {
    Uri url = Uri.parse('https://wa.me/$number');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      setState(() {
        _errorText = 'خطأ';
      });
    }
  }

  void _handleButtonPress() {
    final number = _controller.text;
    if (number.length == 10) {
      if (number.startsWith('052') ||
          number.startsWith('050') ||
          number.startsWith('053') ||
          number.startsWith('054') ||
          number.startsWith('058')) {
        final formattedNumber = '972${number.substring(1)}';
        _launchWhatsApp(formattedNumber);
      } else if (number.startsWith('059') || number.startsWith('056')) {
        final formattedNumber1 = '97$number';
        final formattedNumber2 = '972${number.substring(1)}';
        _showLinkOptions(formattedNumber1, formattedNumber2);
      } else {
        setState(() {
          _errorText = 'مقدمة الرقم خاطئة';
        });
      }
    } else if (number.length == 9) {
      if (number.startsWith('52') ||
          number.startsWith('50') ||
          number.startsWith('53') ||
          number.startsWith('54') ||
          number.startsWith('58')) {
        final formattedNumber = '972$number';
        _launchWhatsApp(formattedNumber);
        SnackBar(
          content: Text('رائع'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Dismiss',
            onPressed: () {
              // Some code to undo the change.
            },
          ),
        );
      } else if (number.startsWith('59') || number.startsWith('56')) {
        final formattedNumber1 = '97$number';
        final formattedNumber2 = '972$number';
        _showLinkOptions(formattedNumber1, formattedNumber2);
        SnackBar(
          content: Text('رائع'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Dismiss',
            onPressed: () {
              // Some code to undo the change.
            },
          ),
        );
      } else {
        setState(() {
          _errorText = 'مقدمة الرقم خاطئة';
        });
      }
    } else if (number.length == 12) {
      _launchWhatsApp(number);
    } else {
      setState(() {
        _errorText = 'يجب أن يتكون الرقم من 9 او 10 او 12 خانة';
      });
    }
  }

  void _showLinkOptions(String number1, String number2) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('اختر'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _launchWhatsApp(number1);
                },
                child: const Text('مقدمة فلسطينية'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _launchWhatsApp(number2);
                },
                child: const Text('مقدمة اسرائيلية'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _requestPermission() async {
    final status = await Permission.contacts.request();
    if (status.isGranted) {
      _openContacts();
    } else {
      setState(() {
        _errorText = 'تم رفض إذن الوصول لجهات الاتصال';

      });
      ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
        content: const Text('تم رفض إذن الوصول لجهات الاتصال',textAlign: TextAlign.center,),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),

      ));

    }
  }

  Future<void> _openContacts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch contacts from SQLite
      _contacts = await _databaseHelper.getContactsList();

      // If no contacts found in SQLite, fetch from ContactsService and store in SQLite
      if (_contacts.isEmpty) {
        final contacts = await ContactsService.getContacts();
        for (var contact in contacts) {
          await _databaseHelper.insertContact({
            'displayName': contact.displayName ?? '',
            'phoneNumber': contact.phones?.isNotEmpty ?? false
                ? contact.phones!.first.value
                : '',
          });
        }
        // Update _contacts after inserting into database
        _contacts = await _databaseHelper.getContactsList();
        SnackBar(
          content: const Text('نجحت العملية'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Dismiss',
            onPressed: () {
              // Some code to undo the change.
            },
          ),
        );
      }
    } catch (e) {
      SnackBar(
        content: Text('Error fetching contacts: $e'),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Dismiss',
          onPressed: () {
            // Some code to undo the change.
          },
        ),
      );
      // Handle error as needed
    } finally {
      setState(() {
        _isLoading = false;
      });
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('اختر جهة اتصال'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: _contacts.length,
              itemBuilder: (context, index) {
                final contact = _contacts[index];
                return ListTile(
                  title: Text(contact.displayName),
                  onTap: () {
                    Navigator.of(context).pop();
                    _controller.text =
                        contact.phoneNumber.replaceAll(RegExp(r'\D'), '');
                    _handleButtonPress();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.right, // Aligns the input text to the right
            decoration: InputDecoration(
              alignLabelWithHint: true,
              labelText: 'أدخل رقم الهاتف',
              errorText: _errorText,
            ),
          ),

          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _handleButtonPress,
            child: const Text('افتح في واتساب'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _requestPermission,
            child: const Text('عرض جهات الاتصال'),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
