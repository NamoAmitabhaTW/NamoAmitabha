import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'flavors.dart';
import 'download_model.dart';
import 'pages/my_home_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) { 
        final m = DownloadModel();
        if (F.appFlavor == Flavor.dev) {
          m.useKws(); 
        } else {
          m.useAsr(); 
        }
        return m;
      },
      child: MaterialApp(
        title: F.title,
        theme: ThemeData(primarySwatch: Colors.blue),
        home: _flavorBanner(
          child: const MyHomePage(), show: kDebugMode),
      ),
    );
  }

  Widget _flavorBanner({required Widget child, bool show = true}) => show
      ? Banner(
          location: BannerLocation.topStart,
          message: F.name,
          color: Colors.green.withAlpha(150),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700, fontSize: 12.0, letterSpacing: 1.0),
          textDirection: TextDirection.ltr,
          child: child,
        )
      : child;
}

typedef MyApp = App;
