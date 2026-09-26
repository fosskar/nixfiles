theme:
let
  vars = p: page: card: field: ''
    --bg: ${page}; --card: ${card}; --field: ${field}; --line: ${p.bg.overlay};
    --ink: ${p.fg.base}; --muted: ${p.fg.muted}; --accent: ${p.accent.primary}; --accent-ink: ${p.fg.inverse};
    --yes: ${p.accent.primary}; --no: ${p.semantic.error};
  '';
in
''
  :root {
    --font: "${theme.fonts.sans}", system-ui, -apple-system, "Segoe UI", sans-serif;
    ${vars theme.light theme.light.bg.surface theme.light.bg.base theme.light.bg.surface}
  }
  @media (prefers-color-scheme: dark) {
    :root {
      ${vars theme.dark theme.dark.bg.base theme.dark.bg.surface theme.dark.bg.elevated}
    }
  }
''
