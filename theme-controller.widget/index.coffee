# theme-controller.widget
#
# Invisible widget. Owns the two theme axes (see THEME.md) and publishes the
# resolved tokens as CSS custom properties on :root, where every other widget
# inherits them via var(--token, <fallback>).
#
#   theme = scheme · mode
#     scheme → a small palette of named colors (one YAML file per scheme in ./themes)
#     mode   → light | dark, i.e. which two poles (wallpaper-driven, or forced)
#
# Renders nothing. Only side effect is writing to document.documentElement.
#
# A theme file is just a list of named colors (red / orange / … / pink) as hex.
# This widget derives each color's RGB channels and the full role contract
# (status ramp, data series, area-fills, etc.) from them — so authoring a theme
# is just picking ~7 colors, no rgba() or role wiring. Theme files are YAML (plain
# data, so they can carry comments/attribution), which Übersicht does not load as
# widgets. monochrome is the one exception: it has no hues (ink at opacities).

# --- Configuration --------------------------------------------------------
scheme:     'iOS'           # 'monochrome' | 'macOS' | 'Apple Classic' | 'iOS' | 'Monokai' | 'Monokai Pro' | 'Dracula' | 'Solarized' | 'Nord Frost' | 'Nord Aurora' | 'Tokyo Night'
modeSource: 'wallpaper'    # 'wallpaper' → match the menu-bar tint (wallpaper brightness);
                           # or force 'light' / 'dark'
darknessThreshold: 32      # 0(white)..100(black). Wallpaper darkness ≥ this ⇒ dark wallpaper
                           # ⇒ macOS uses white menu-bar text ⇒ our 'light' mode (white ink).

# Capture the menu-bar strip and print its darkness (0=white..100=black), matching
# the signal macOS keys its menu-bar text color off. Requires the Übersicht app to
# have Screen Recording permission (System Settings → Privacy & Security).
command: "theme-controller.widget/lib/darkness.sh"

# Enable or disable this widget.
widgetEnabled: true   # true | false

refreshFrequency: 5000

# --- Mode layer: the two poles per mode -----------------------------------
# ink = content color · panelInk = panel-tint base. Comma-triplets so they drop
# straight into rgba(...). This is the ENTIRE difference between modes.
modes:
  light: { ink: '255, 255, 255', panelInk: '0, 0, 0' }
  dark:  { ink: '0, 0, 0',       panelInk: '255, 255, 255' }

# --- Neutrals: mode-driven, shared by every scheme ------------------------
# Every neutral is the mode's ink at a stepped opacity. `--ink` exposes the raw
# triplet so the monochrome scheme can derive its shades from the mode.
neutrals: (m) ->
  '--ink':          m.ink
  '--panel-bg':     "rgba(#{m.panelInk}, .15)"
  '--panel-blur':   "48px"
  '--text':         "rgb(#{m.ink})"
  '--level-max':    "rgba(#{m.ink}, 1)"
  '--level-hi':     "rgba(#{m.ink}, .8)"
  '--level-mid':    "rgba(#{m.ink}, .6)"
  '--level-lo':     "rgba(#{m.ink}, .4)"
  '--level-base':   "rgba(#{m.ink}, .05)"
  '--text-secondary': "rgba(#{m.ink}, .5)"
  '--area-fill-lo': "rgba(#{m.ink}, .15)"
  '--area-fill-hi': "rgba(#{m.ink}, .3)"
  '--hairline':     "rgba(#{m.ink}, .125)"  # faint borders (graph container)
  '--dot-grid':     "rgba(#{m.ink}, .05)"   # graph dot-grid background

# --- Role contract: identical for every color theme -----------------------
# References the palette a theme provides (--red, --green, …) and their derived
# -ch channel variants. Fills are rgba(var(--x-ch), α) so a theme never writes an
# rgba literal. --red/--green/--blue/--pink themselves come straight from the
# theme's colors; --green-ch (github) and --blue (network) do too.
roles:
  '--status-ok':        'var(--green)'
  '--status-warn':      'var(--yellow)'
  '--status-elevated':  'var(--orange)'
  '--status-critical':  'var(--red)'
  '--series-primary':      'var(--red)'
  '--series-secondary':    'var(--orange)'
  '--series-tertiary':     'var(--yellow)'
  '--series-quaternary':   'var(--green)'
  '--series-primary-fill':    'rgba(var(--red-ch), .3)'
  '--series-secondary-fill':  'rgba(var(--orange-ch), .25)'
  '--series-tertiary-fill':   'rgba(var(--yellow-ch), .2)'
  '--series-quaternary-fill': 'rgba(var(--green-ch), .15)'
  '--status-ok-fill':       'rgba(var(--green-ch), .3)'
  '--status-warn-fill':     'rgba(var(--yellow-ch), .3)'
  '--status-elevated-fill': 'rgba(var(--orange-ch), .3)'
  '--status-critical-fill': 'rgba(var(--red-ch), .3)'
  '--blue-fill':            'rgba(var(--blue-ch), .25)'  # network upload area
  '--wx-icon-accent':       'visible'

# monochrome: no hues. Series + pink + blue are the mode's ink at stepped
# opacities; status/fills stay unset so widgets fall back to their own ink.
monoRoles: (m) ->
  '--pink':              "rgba(#{m.ink}, 1)"
  '--series-primary':    "rgba(#{m.ink}, 1)"
  '--series-secondary':  "rgba(#{m.ink}, .5)"
  '--series-tertiary':   "rgba(#{m.ink}, .35)"
  '--series-quaternary': "rgba(#{m.ink}, .2)"
  '--blue':              "rgba(#{m.ink}, .5)"   # network upload bar
  '--primary':           "rgba(#{m.ink}, 1)"    # accents are just ink here
  '--secondary':         "rgba(#{m.ink}, .6)"
  '--primary-ch':        m.ink
  '--secondary-ch':      m.ink

# --- Accents: scheme-owned, mode-independent ------------------------------
accents:
  '--warn-low': '#df5077'
  '--warn-mid': '#f0c050'
  '--loved':    '#e84341'

# --- Theme loading --------------------------------------------------------
# Scheme name → file slug: lowercased, spaces → hyphens ('Apple Classic' →
# 'apple-classic'). Fetched same-origin from the widget's own served files.
schemePath: -> "theme-controller.widget/themes/#{@scheme.toLowerCase().replace(/\s+/g, '-')}.yaml"

# "#RRGGBB" → "r, g, b" (for rgba() fills). Returns null for non-hex values.
hexToChannels: (hex) ->
  h = (hex or '').replace('#', '').trim()
  return null unless h.length is 6
  "#{parseInt(h[0..1], 16)}, #{parseInt(h[2..3], 16)}, #{parseInt(h[4..5], 16)}"

# Minimal parser for our flat "name: value" YAML color files. Not a full YAML
# parser — just a map of scalars plus `#` comments. Quote-aware, because color
# values start with `#` (YAML's comment character), so values must be quoted.
parseTheme: (text) ->
  stripComment = (line) ->
    q = false
    for ch, i in line
      q = not q if ch is '"'
      return line[0...i] if ch is '#' and not q
    line
  clean = (s) ->
    s = s.trim()
    if s.length >= 2 and s[0] is '"' and s[s.length - 1] is '"' then s[1...s.length - 1] else s
  out = {}
  for raw in (text or '').split('\n')
    line = stripComment(raw)
    continue unless line.trim().length
    q = false; ci = -1
    for ch, i in line
      q = not q if ch is '"'
      if ch is ':' and not q then ci = i; break
    continue if ci < 0
    key = clean(line[0...ci])
    out[key] = clean(line[ci + 1..]) if key.length
  out

loadTheme: ->
  self = this
  @_themePromise ?= fetch(@schemePath())
    .then((r) -> r.text())
    .then((t) -> self.parseTheme(t))
    .catch(-> {})   # on failure, neutrals still apply; widgets use their own fallbacks
  @_themePromise

# --- Wiring ---------------------------------------------------------------
render: -> ""

style: """
  display: none
"""

update: (output, domEl) ->
  # When disabled, don't publish theme tokens (widgets fall back to their own).
  return unless @widgetEnabled
  self = this
  @loadTheme().then (colors) ->
    raw = (output or '').trim()
    mode =
      if self.modeSource in ['light', 'dark'] then self.modeSource
      else
        # 'wallpaper': output is menu-bar darkness 0(white)..100(black).
        d = parseInt(raw, 10)
        if isFinite(d)
          if d >= self.darknessThreshold then 'light' else 'dark'
        else
          self.applied or 'light'   # capture failed (e.g. no permission) — hold/default

    # Only rewrite on an actual change — no per-tick DOM thrash.
    return if mode is self.applied and self.scheme is self.appliedScheme

    poles = self.modes[mode]
    return unless poles
    root = document.documentElement
    set = (name, value) -> root.style.setProperty(name, value)

    # 1) mode-driven neutrals (always)
    set(name, value) for name, value of self.neutrals(poles)

    if colors and Object.keys(colors).length > 0
      # 2a) color theme: publish each named color + its channel triplet, then the
      #     shared role contract (which references them).
      # palette: each named color + its channel triplet ('primary'/'secondary'
      # are aliases handled below, not colors themselves).
      for name, hex of colors when name isnt 'primary' and name isnt 'secondary'
        set("--#{name}", hex)
        ch = self.hexToChannels(hex)
        set("--#{name}-ch", ch) if ch
      set(name, value) for name, value of self.roles
      # Semantic accent pair — aliases into the palette (default primary → pink,
      # secondary → purple/blue). Widgets use these for brand-accent elements.
      p = colors.primary   or (if colors.pink   then 'pink'   else 'red')
      s = colors.secondary or (if colors.purple then 'purple' else 'blue')
      set('--primary',      "var(--#{p})")
      set('--primary-ch',   "var(--#{p}-ch)")
      set('--secondary',    "var(--#{s})")
      set('--secondary-ch', "var(--#{s}-ch)")
      # optional: a theme may tint the translucent panels with its own background
      # color, overriding the neutral tint. `background-opacity` (0–1, default .3)
      # sets how solid it is: low = a subtle wash, 1 = a fully opaque panel.
      if colors.background
        op = colors['background-opacity'] or '.3'
        set('--panel-bg', "rgba(var(--background-ch), #{op})")
    else
      # 2b) monochrome / ink-only
      set(name, value) for name, value of self.monoRoles(poles)

    # 3) mode-independent accents
    set(name, value) for name, value of self.accents

    root.setAttribute 'data-mode', mode
    root.setAttribute 'data-scheme', self.scheme
    self.applied = mode
    self.appliedScheme = self.scheme
