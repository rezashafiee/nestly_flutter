import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/network/api_client.dart';
import '../core/offline/offline_json_store.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/state/auth_controller.dart';
import '../features/chat/data/chat_repository.dart';
import '../features/chat/state/chat_controller.dart';
import '../features/marketplace/data/listings_repository.dart';
import '../features/marketplace/state/marketplace_controller.dart';
import '../features/sell/data/photo_repository.dart';
import 'app_controller.dart';
import 'app_router.dart';

class NestlyApp extends StatefulWidget {
  const NestlyApp({
    super.key,
    this.apiClient,
    this.authRepository,
    this.listingsRepository,
    this.chatRepository,
    this.photoRepository,
  });

  final NestlyApiClient? apiClient;
  final AuthRepository? authRepository;
  final ListingsRepository? listingsRepository;
  final ChatRepository? chatRepository;
  final PhotoRepository? photoRepository;

  @override
  State<NestlyApp> createState() => _NestlyAppState();
}

class _NestlyAppState extends State<NestlyApp> {
  late final NestlyApiClient _apiClient;
  late final OfflineJsonStore _offlineStore;
  late final bool _ownsApiClient;
  late final AppController _appController;
  late final AuthRepository _authRepository;
  late final ListingsRepository _listingsRepository;
  late final ChatRepository _chatRepository;
  late final PhotoRepository _photoRepository;
  late final AuthController _authController;
  late final MarketplaceController _marketplaceController;
  late final ChatController _chatController;
  late final MergedListenable _routerRefresh = MergedListenable([
    _appController,
    _authController,
  ]);
  late final _router = createAppRouter(
    appController: _appController,
    authController: _authController,
    refreshListenable: _routerRefresh,
  );

  @override
  void initState() {
    super.initState();
    _apiClient = widget.apiClient ?? NestlyApiClient();
    _offlineStore = OfflineJsonStore();
    _ownsApiClient = widget.apiClient == null;
    _appController = AppController()..start();
    _authRepository =
        widget.authRepository ??
        AuthRepository(apiClient: _apiClient, offlineStore: _offlineStore);
    _listingsRepository =
        widget.listingsRepository ??
        ListingsRepository(apiClient: _apiClient, offlineStore: _offlineStore);
    _chatRepository =
        widget.chatRepository ??
        ChatRepository(apiClient: _apiClient, offlineStore: _offlineStore);
    _photoRepository = widget.photoRepository ?? PhotoRepository();
    _authController = AuthController(_authRepository);
    unawaited(_authController.restoreSession());
    _marketplaceController = MarketplaceController(_listingsRepository);
    _chatController = ChatController(_chatRepository);
  }

  @override
  void dispose() {
    _router.dispose();
    _routerRefresh.dispose();
    _chatController.dispose();
    _marketplaceController.dispose();
    _authController.dispose();
    _appController.dispose();
    if (_ownsApiClient) {
      _apiClient.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: _authRepository),
        Provider<ListingsRepository>.value(value: _listingsRepository),
        Provider<ChatRepository>.value(value: _chatRepository),
        Provider<PhotoRepository>.value(value: _photoRepository),
        ChangeNotifierProvider<AppController>.value(value: _appController),
        ChangeNotifierProvider<AuthController>.value(value: _authController),
        ChangeNotifierProvider<MarketplaceController>.value(
          value: _marketplaceController,
        ),
        ChangeNotifierProvider<ChatController>.value(value: _chatController),
      ],
      child: MaterialApp.router(
        title: 'Nestly',
        debugShowCheckedModeBanner: false,
        theme: buildNestlyTheme(),
        routerConfig: _router,
      ),
    );
  }
}
