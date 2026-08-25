const String _cardsPath = '/cards';
const String _onboardingPath = '/onboarding';

String? cardsAuthRedirect(Uri uri, bool isAuthed) {
  final bool isCards = _isCardsPath(uri.path);

  if (!isAuthed) {
    if (isCards) {
      return '$_onboardingPath?next=${Uri.encodeComponent(uri.toString())}';
    }

    return null;
  }

  if (uri.path == _onboardingPath) {
    return _safeNext(uri.queryParameters['next']) ?? _cardsPath;
  }

  return null;
}

bool _isCardsPath(String path) {
  return path == _cardsPath || path.startsWith('$_cardsPath/');
}

String? _safeNext(String? next) {
  if (next == null || next.isEmpty) {
    return null;
  }

  final Uri parsed;

  try {
    parsed = Uri.parse(next);
  } on FormatException {
    return null;
  }

  if (parsed.hasScheme || parsed.hasAuthority) {
    return null;
  }

  if (!_isCardsPath(parsed.path)) {
    return null;
  }

  return next;
}
