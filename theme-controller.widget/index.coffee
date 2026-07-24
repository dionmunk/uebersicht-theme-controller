# theme-controller.widget
#
# Invisible widget. Owns the two theme axes (see THEME.md) and publishes the
# resolved tokens as CSS custom properties on :root, where every other widget
# inherits them via var(--token, <fallback>).
#
#   theme = scheme · mode
#     scheme → which palette + accents (one JSON file per scheme in ./themes)
#     mode   → light | dark, i.e. which two poles (wallpaper-driven, or forced)
#
# Renders nothing. Only side effect is writing to document.documentElement.
# The per-scheme palettes live in ./themes/*.json — plain DATA files, so Übersicht
# does not pick them up as widgets. The active scheme is fetched at runtime.

# --- Configuration --------------------------------------------------------
scheme:     'iOS'          # 'monochrome' | 'macOS' | 'Apple Classic' | 'iOS'
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
# ink = content color · panelInk = panel-tint base. Comma-triplets so they drop
# straight into rgba(...). This is the ENTIRE difference between modes.
modes:
  light: { ink: '255, 255, 255', panelInk: '0, 0, 0' }
  dark:  { ink: '0, 0, 0',       panelInk: '255, 255, 255' }

# --- Neutrals: mode-driven, shared by every scheme ------------------------
# Every neutral is the mode's ink at a stepped opacity. Schemes layer color on
# top. `--ink` exposes the raw triplet so a scheme file can derive its own shades
# from the mode (monochrome does: rgba(var(--ink), α)).
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
  '--secondary':    "rgba(#{m.ink}, .5)"
  '--area-fill-lo': "rgba(#{m.ink}, .15)"
  '--area-fill-hi': "rgba(#{m.ink}, .3)"
  '--hairline':     "rgba(#{m.ink}, .125)"  # faint borders (graph container)
  '--dot-grid':     "rgba(#{m.ink}, .05)"   # graph dot-grid background

# --- Accents: scheme-owned, mode-independent ------------------------------
accents:
  '--warn-low': '#df5077'
  '--warn-mid': '#f0c050'
  '--loved':    '#e84341'

# --- Theme loading: fetch the active scheme's JSON once (cached) ----------
# Scheme name → file slug: lowercased, spaces → hyphens ('Apple Classic' →
# 'apple-classic'). Fetched same-origin from the widget's own served files.
schemePath: -> "theme-controller.widget/themes/#{@scheme.toLowerCase().replace(/\s+/g, '-')}.json"

loadTheme: ->
  @_themePromise ?= fetch(@schemePath())
    .then((r) -> r.json())
    .catch(-> {})   # on failure, neutrals still apply; widgets use their own fallbacks
  @_themePromise

# --- Wiring ---------------------------------------------------------------
render: -> ""

style: """
  display: none
"""

update: (output, domEl) ->
  self = this
  @loadTheme().then (themeTokens) ->
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
    tokens = Object.assign {}, self.neutrals(poles), (themeTokens or {})

    root = document.documentElement
    root.style.setProperty(name, value) for name, value of tokens
    root.style.setProperty(name, value) for name, value of self.accents
    root.setAttribute 'data-mode', mode
    root.setAttribute 'data-scheme', self.scheme

    self.applied = mode
    self.appliedScheme = self.scheme
