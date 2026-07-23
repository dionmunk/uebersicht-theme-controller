# theme-controller.widget
#
# Invisible widget. Owns the two theme axes (see THEME.md) and publishes the
# resolved tokens as CSS custom properties on :root, where every other widget
# inherits them via var(--token, <light fallback>).
#
#   theme = scheme · mode
#     scheme  → which derivation + accents        (config below)
#     mode    → light | dark, i.e. which two poles (auto from macOS, or forced)
#
# Renders nothing. Only side effect is writing to document.documentElement.

# --- Configuration --------------------------------------------------------
scheme:     'iOS'          # which scheme's derivation + accents to apply
modeSource: 'wallpaper'    # 'wallpaper' → match the menu-bar tint (wallpaper brightness);
                           # or force 'light' / 'dark'
darknessThreshold: 32      # 0(white)..100(black). Wallpaper darkness ≥ this ⇒ dark wallpaper
                           # ⇒ macOS uses white menu-bar text ⇒ our 'light' mode (white ink).

# Capture the menu-bar strip and print its darkness (0=white..100=black), matching
# the signal macOS keys its menu-bar text color off. Requires the Übersicht app to
# have Screen Recording permission (System Settings → Privacy & Security).
command: "theme-controller.widget/lib/darkness.sh"

refreshFrequency: 5000

# --- Mode layer: the two poles per mode -----------------------------------
# ink       = content color · panelInk = panel-tint base. Comma-triplets so they
# drop straight into rgba(...). This is the ENTIRE difference between modes.
modes:
  light: { ink: '255, 255, 255', panelInk: '0, 0, 0' }
  dark:  { ink: '0, 0, 0',       panelInk: '255, 255, 255' }

# --- Neutrals: mode-driven, shared by every scheme ------------------------
# Every neutral is the mode's ink at a stepped opacity. Schemes layer color on
# top of these (and may override any of them).
neutrals: (m) ->
  '--panel-bg':     "rgba(#{m.panelInk}, .15)"
  '--panel-blur':   "48px"
  '--text':         "rgb(#{m.ink})"
  '--level-max':    "rgba(#{m.ink}, 1)"
  '--level-hi':     "rgba(#{m.ink}, .8)"
  '--level-mid':    "rgba(#{m.ink}, .6)"
  '--level-lo':     "rgba(#{m.ink}, .4)"
  '--level-base':   "rgba(#{m.ink}, .05)"
  '--secondary':    "rgba(#{m.ink}, .5)"
  '--area-fill-lo': "rgba(#{m.ink}, .15)"
  '--area-fill-hi': "rgba(#{m.ink}, .3)"
  '--hairline':     "rgba(#{m.ink}, .125)"  # faint borders (graph container)
  '--dot-grid':     "rgba(#{m.ink}, .05)"   # graph dot-grid background

# --- Scheme layer: color tokens layered on the neutrals -------------------
schemes:
  # monochrome: no hues, but it DOES publish ink-based translucent series tokens so
  # the bars follow the mode — a static rgba(#fff,…) widget fallback can't flip to
  # black ink. Same alphas as those fallbacks; cumulative layering keeps them clean.
  monochrome: (m) ->
    '--series-primary':    "rgba(#{m.ink}, 1)"
    '--series-secondary':  "rgba(#{m.ink}, .5)"
    '--series-tertiary':   "rgba(#{m.ink}, .35)"
    '--series-quaternary': "rgba(#{m.ink}, .2)"
    '--apple-blue':        "rgba(#{m.ink}, .5)"

  # macOS: the modern macOS accent-colour palette. Neutrals still follow the mode; the
  # six hues are exposed as --macos-*, and the status/series roles map onto them.
  macOS: (m) ->
    '--macos-red':    '#ee4f43'
    '--macos-orange': '#f3933b'
    '--macos-yellow': '#f9cc38'
    '--macos-green':  '#61c262'
    '--macos-teal':   '#54c4b3'
    '--macos-blue':   '#4ebee5'
    '--status-ok':        'var(--macos-green)'
    '--status-warn':      'var(--macos-yellow)'
    '--status-elevated':  'var(--macos-orange)'
    '--status-critical':  'var(--macos-red)'
    # Data-series identities. Solid tokens drive bars/lines; -fill tokens are the
    # same hue at a stacked-area opacity ramp (.3/.25/.2/.15 by series position).
    # Full colors (not channels) because Übersicht's Stylus rejects rgba(var(),…).
    '--series-primary':      'var(--macos-red)'     # 1st series → red
    '--series-secondary':    'var(--macos-orange)'  # 2nd series → orange
    '--series-tertiary':     'var(--macos-yellow)'  # 3rd series → yellow
    '--series-quaternary':   'var(--macos-green)'   # 4th series → green
    '--series-primary-fill':    'rgba(238, 79, 67, .3)'    # red    @ .3
    '--series-secondary-fill':  'rgba(243, 147, 59, .25)'  # orange @ .25
    '--series-tertiary-fill':   'rgba(249, 204, 56, .2)'   # yellow @ .2
    '--series-quaternary-fill': 'rgba(97, 194, 98, .15)'   # green  @ .15
    # status area-fills (e.g. storage graph — matches the status ramp @ .3)
    '--status-ok-fill':        'rgba(97, 194, 98, .3)'     # green  @ .3
    '--status-warn-fill':      'rgba(249, 204, 56, .3)'    # yellow @ .3
    '--status-elevated-fill':  'rgba(243, 147, 59, .3)'    # orange @ .3
    '--status-critical-fill':  'rgba(238, 79, 67, .3)'     # red    @ .3
    # shared widget-contract tokens (network upload + github read the --apple-* names)
    '--apple-blue':            'var(--macos-blue)'          # network upload bar
    '--apple-blue-fill':       'rgba(78, 190, 229, .25)'   # blue   @ .25
    '--apple-green-ch':        '97, 194, 98'               # github green channels #61c262
    '--wx-icon-accent':        'visible'

  # Apple Classic: the 1977 rainbow-logo colours (green/yellow/orange/red/purple/blue).
  'Apple Classic': (m) ->
    '--classic-green':  '#61BB46'
    '--classic-yellow': '#FDB827'
    '--classic-orange': '#F5821F'
    '--classic-red':    '#E03A3E'
    '--classic-purple': '#963D97'
    '--classic-blue':   '#009DDC'
    '--status-ok':        'var(--classic-green)'
    '--status-warn':      'var(--classic-yellow)'
    '--status-elevated':  'var(--classic-orange)'
    '--status-critical':  'var(--classic-red)'
    '--series-primary':      'var(--classic-red)'     # 1st series → red
    '--series-secondary':    'var(--classic-orange)'  # 2nd series → orange
    '--series-tertiary':     'var(--classic-yellow)'  # 3rd series → yellow
    '--series-quaternary':   'var(--classic-green)'   # 4th series → green
    '--series-primary-fill':    'rgba(224, 58, 62, .3)'    # red    #E03A3E @ .3
    '--series-secondary-fill':  'rgba(245, 130, 31, .25)'  # orange #F5821F @ .25
    '--series-tertiary-fill':   'rgba(253, 184, 39, .2)'   # yellow #FDB827 @ .2
    '--series-quaternary-fill': 'rgba(97, 187, 70, .15)'   # green  #61BB46 @ .15
    '--status-ok-fill':        'rgba(97, 187, 70, .3)'     # green
    '--status-warn-fill':      'rgba(253, 184, 39, .3)'    # yellow
    '--status-elevated-fill':  'rgba(245, 130, 31, .3)'    # orange
    '--status-critical-fill':  'rgba(224, 58, 62, .3)'     # red
    '--apple-blue':            'var(--classic-blue)'        # network upload bar
    '--apple-blue-fill':       'rgba(0, 157, 220, .25)'    # blue #009DDC @ .25
    '--apple-green-ch':        '97, 187, 70'               # github green channels #61BB46
    '--wx-icon-accent':        'visible'

  # iOS: the official iOS system palette (same role mapping as apple). Exposes the
  # nine hues as --ios-*; network-upload + github read the shared --apple-* names,
  # so those get fed the iOS blue/green here too.
  iOS: (m) ->
    '--ios-red':    '#FF3B30'
    '--ios-orange': '#FF9500'
    '--ios-yellow': '#FFCC00'
    '--ios-green':  '#34C759'
    '--ios-teal':   '#5AC8FA'
    '--ios-blue':   '#007AFF'
    '--ios-indigo': '#5856D6'
    '--ios-pink':   '#FF2D55'
    '--ios-purple': '#AF52DE'
    '--status-ok':        'var(--ios-green)'
    '--status-warn':      'var(--ios-yellow)'
    '--status-elevated':  'var(--ios-orange)'
    '--status-critical':  'var(--ios-red)'
    '--series-primary':      'var(--ios-red)'     # 1st series → red
    '--series-secondary':    'var(--ios-orange)'  # 2nd series → orange
    '--series-tertiary':     'var(--ios-yellow)'  # 3rd series → yellow
    '--series-quaternary':   'var(--ios-green)'   # 4th series → green
    '--series-primary-fill':    'rgba(255, 59, 48, .3)'    # red    #FF3B30 @ .3
    '--series-secondary-fill':  'rgba(255, 149, 0, .25)'   # orange #FF9500 @ .25
    '--series-tertiary-fill':   'rgba(255, 204, 0, .2)'    # yellow #FFCC00 @ .2
    '--series-quaternary-fill': 'rgba(52, 199, 89, .15)'   # green  #34C759 @ .15
    '--status-ok-fill':        'rgba(52, 199, 89, .3)'     # green
    '--status-warn-fill':      'rgba(255, 204, 0, .3)'     # yellow
    '--status-elevated-fill':  'rgba(255, 149, 0, .3)'     # orange
    '--status-critical-fill':  'rgba(255, 59, 48, .3)'     # red
    '--apple-blue':            'var(--ios-blue)'            # network upload (widget reads --apple-blue)
    '--apple-blue-fill':       'rgba(0, 122, 255, .25)'    # blue #007AFF @ .25
    '--apple-green-ch':        '52, 199, 89'               # github green channels #34C759
    '--wx-icon-accent':        'visible'

# --- Accents: scheme-owned, mode-independent ------------------------------
accents:
  '--warn-low': '#df5077'
  '--warn-mid': '#f0c050'
  '--loved':    '#e84341'

# --- Wiring ---------------------------------------------------------------
render: -> ""

style: """
  display: none
"""

update: (output, domEl) ->
  raw = (output or '').trim()
  mode =
    if @modeSource in ['light', 'dark'] then @modeSource
    else
      # 'wallpaper': output is menu-bar darkness 0(white)..100(black).
      d = parseInt(raw, 10)
      if isFinite(d)
        if d >= @darknessThreshold then 'light' else 'dark'
      else
        @applied or 'light'   # capture failed (e.g. no permission) — hold/default

  # Only rewrite on an actual change — no per-tick DOM thrash.
  return if mode is @applied and @scheme is @appliedScheme

  poles = @modes[mode]
  return unless poles and @schemes[@scheme]
  tokens = Object.assign {}, @neutrals(poles), @schemes[@scheme](poles)

  root = document.documentElement
  root.style.setProperty(name, value) for name, value of tokens
  root.style.setProperty(name, value) for name, value of @accents
  root.setAttribute 'data-mode', mode
  root.setAttribute 'data-scheme', @scheme

  @applied = mode
  @appliedScheme = @scheme
