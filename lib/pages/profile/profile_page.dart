import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../auth/auth_store.dart';
import '../../navigation/route_history.dart';
import '../../theme/tuuuur_theme.dart';
import '../../widgets/gaming_widgets.dart';
import '../../widgets/navigation_header.dart';
import '../../api/auth_api_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _loading = false;
  String? _nickName;
  String? _email;
  String? _avatar; // valeur renvoyée par l’API (url, base64, data-uri…)
  int? _userId;

  Uint8List? _avatarBytes; // bytes à afficher (aperçu local OU décodage base64 serveur)
  final _picker = ImagePicker();

  bool _fetched = false;

  String get _fallbackAvatarUrl {
    final seed = Uri.encodeComponent(_nickName ?? 'player');
    return 'https://api.dicebear.com/9.x/adventurer-neutral/svg?seed=$seed';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchMeOnce();
  }

  Uint8List? _tryDecodeBase64(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      var raw = s.trim();
      final comma = raw.indexOf(',');
      if (raw.startsWith('data:image') && comma != -1) {
        raw = raw.substring(comma + 1);
      }
      return base64Decode(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> _fetchMeOnce() async {
    if (_fetched) return;
    _fetched = true;

    final store = MyAuthStore.of(context);
    if (!store.isAuthenticated) return;

    setState(() => _loading = true);
    final res = await authApi.me(headers: store.authHeaders);
    if (!mounted) return;
    setState(() => _loading = false);

    if (res.ok && res.data != null) {
      final u = res.data!;
      final val = u.avatar;
      final decoded = _tryDecodeBase64(val);

      setState(() {
        _nickName = u.nickName;
        _email = u.email;
        _avatar = val;
        _userId = u.id;
        _avatarBytes = decoded ?? _avatarBytes;
      });
    } else if (res.statusCode == 401) {
      await store.signOut();
      if (!mounted) return;
      _toast('Session expirée. Veuillez vous reconnecter.');
    } else {
      _toast(res.message ?? 'Impossible de charger le profil.');
    }
  }

  void _toast(String m, {Color color = TuuurTheme.brandOrange}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: color),
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final xfile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (xfile == null) return;

      final bytes = await xfile.readAsBytes();
      setState(() => _avatarBytes = bytes);

      final base64Str = base64Encode(bytes);
      final store = MyAuthStore.of(context);

      setState(() => _loading = true);
      final res = await authApi.updateAvatarBase64(
        base64: base64Str,
        headers: store.authHeaders,
      );
      if (!mounted) return;
      setState(() => _loading = false);

      if (res.ok) {
        _toast('Avatar mis à jour ✅', color: TuuurTheme.brandGreen);
        _fetched = false;
        await _fetchMeOnce();
      } else {
        _toast(res.message ?? 'Échec de la mise à jour de l’avatar.');
      }
    } catch (e) {
      _toast('Erreur avatar : $e');
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TuuurTheme.brandDarkGray,
        title: const Text('Supprimer le compte', style: TextStyle(color: TuuurTheme.brandLightGray)),
        content: const Text('Cette action est irréversible. Confirmer ?',
            style: TextStyle(color: TuuurTheme.brandGray)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
          GamingButtonSecondary(text: 'Supprimer', onPressed: () => Navigator.of(ctx).pop(true)),
        ],
      ),
    );
    if (confirm != true) return;

    final store = MyAuthStore.of(context);
    setState(() => _loading = true);
    final res = await authApi.deleteMe(headers: store.authHeaders);
    if (!mounted) return;
    setState(() => _loading = false);

    if (res.ok) {
      await store.signOut();
      if (!mounted) return;
      _toast('Compte supprimé.', color: TuuurTheme.brandGreen);
      context.go('/');
    } else {
      _toast(res.message ?? 'Suppression impossible.');
    }
  }

  Future<void> _signOut() async {
    final store = MyAuthStore.of(context);
    await store.signOut();
    if (!mounted) return;
    // Nettoie l’état local pour éviter un vieux rendu
    setState(() {
      _nickName = null;
      _email = null;
      _avatar = null;
      _userId = null;
      _avatarBytes = null;
      _fetched = false;
    });
    _toast('Déconnecté.', color: TuuurTheme.brandGreen);
    context.go('/'); // Retour à l’accueil
  }

  @override
  Widget build(BuildContext context) {
    final store = MyAuthStore.of(context);
    final isAuthenticated = store.isAuthenticated;

    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        RouteHistory.instance.navigateBack(context);
      },
      child: Scaffold(
        backgroundColor: TuuurTheme.brandDark,
        appBar: const NavigationHeader(),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),

              Row(
                children: const [
                  Text('👤', style: TextStyle(fontSize: 28)),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Profil',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: TuuurTheme.brandLightGray,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (!isAuthenticated) ...[
                _notConnectedCard(isMobile),
              ] else ...[
                if (_loading && _nickName == null)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: TuuurStyles.gamingCard,
                    child: const Center(
                      child: CircularProgressIndicator(color: TuuurTheme.brandPurple),
                    ),
                  )
                else
                  _profileCard(isMobile),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _notConnectedCard(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: TuuurStyles.gamingCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Vous n’êtes pas connecté',
            style: TextStyle(
              color: TuuurTheme.brandLightGray,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          if (isMobile)
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: GamingButtonPrimary(
                    text: '🚀 Se connecter',
                    onPressed: () => context.push('/login'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: GamingButtonSecondary(
                    text: '🔗 Créer un compte',
                    onPressed: () => context.push('/register'),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: GamingButtonPrimary(
                    text: '🚀 Se connecter',
                    onPressed: () => context.push('/login'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GamingButtonSecondary(
                    text: '🔗 Créer un compte',
                    onPressed: () => context.push('/register'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _profileCard(bool isMobile) {
    final name = _nickName ?? 'Joueur';
    final avatarUrl = (_avatar != null && _avatar!.startsWith('http')) ? _avatar! : _fallbackAvatarUrl;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: TuuurStyles.gamingCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Avatar(avatarUrl: avatarUrl, bytes: _avatarBytes, base64OrDataUri: _avatar),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: TuuurTheme.brandLightGray,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GamingButtonSecondary(
                  text: '⚙️ Modifier avatar',
                  onPressed: _pickAndUploadAvatar,
                ),
                const SizedBox(height: 12),
                GamingButtonPrimary(
                  text: '🔑 Réinitialiser le mot de passe',
                  onPressed: () => context.push('/change-password'),
                ),
                const SizedBox(height: 12),
                GamingButtonSecondary(
                  text: '🚪 Se déconnecter',
                  onPressed: _signOut,
                ),
                const SizedBox(height: 12),
                GamingButtonSecondary(
                  text: '🗑️ Supprimer mon compte',
                  onPressed: _deleteAccount,
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: GamingButtonSecondary(
                    text: '⚙️ Modifier avatar',
                    onPressed: _pickAndUploadAvatar,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GamingButtonPrimary(
                    text: '🔑 Réinitialiser le mot de passe',
                    onPressed: () => context.push('/change-password'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GamingButtonSecondary(
                    text: '🚪 Se déconnecter',
                    onPressed: _signOut,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GamingButtonSecondary(
                    text: '🗑️ Supprimer mon compte',
                    onPressed: _deleteAccount,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String avatarUrl;            // utilisé si bytes null ET pas de base64
  final Uint8List? bytes;            // priorité d’affichage
  final String? base64OrDataUri;     // si présent, tentative de décodage interne

  const _Avatar({
    required this.avatarUrl,
    this.bytes,
    this.base64OrDataUri,
  });

  Uint8List? _decode(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      var raw = s.trim();
      final comma = raw.indexOf(',');
      if (raw.startsWith('data:image') && comma != -1) {
        raw = raw.substring(comma + 1);
      }
      return base64Decode(raw);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget img;

    if (bytes != null) {
      img = Image.memory(bytes!, fit: BoxFit.cover, width: 60, height: 60);
    } else {
      final decoded = _decode(base64OrDataUri);
      if (decoded != null) {
        img = Image.memory(decoded, fit: BoxFit.cover, width: 60, height: 60);
      } else {
        img = Image.network(
          avatarUrl,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: TuuurTheme.brandPurple.withOpacity(0.2),
            child: const Icon(Icons.person, color: TuuurTheme.brandPurple, size: 30),
          ),
        );
      }
    }

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: TuuurTheme.brandPurple, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: img,
      ),
    );
  }
}
