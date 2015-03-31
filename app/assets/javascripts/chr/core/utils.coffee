# -----------------------------------------------------------------------------
# UTILS

# _last(array)
@_last = (array) -> array[array.length - 1]

# _first(array)
@_first = (array) -> array[0]

# _firstNonEmptyValue(hash)
@_firstNonEmptyValue = (o) -> ((return v if k[0] != '_' and v and v != '') for k, v of o) ; return null

# _stripHtml(string)
@_stripHtml = (string) -> String(string).replace(/<\/?[^>]+(>|$)/g, "")

# _escapeHtml(string)
@_entityMap  = { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': '&quot;', "'": '&#39;', "/": '&#x2F;' }
@_escapeHtml = (string) -> String(string).replace /[&<>"'\/]/g, (s) -> _entityMap[s]

# String.titleize
if typeof String.prototype.titleize != 'function'
  String.prototype.titleize = () -> return this.replace(/_/g, ' ').replace(/\b./g, ((m) -> m.toUpperCase()))

# String.reverse
if typeof String.prototype.reverse != 'function'
  String.prototype.reverse = (str) -> return this.split("").reverse().join("")

# String.startsWith
if typeof String.prototype.startsWith != 'function'
  String.prototype.startsWith = (str) -> return this.slice(0, str.length) == str

# String.endsWith
if typeof String.prototype.endsWith != 'function'
  String.prototype.endsWith = (str) -> return this.slice(this.length - str.length, this.length) == str

# -----------------------------------------------------------------------------
# HELPERS

# Helps to figure out how many list items fits screen height
@_itemsPerScreen      = -> itemHeight = 60 ; return Math.ceil($(window).height() / itemHeight)
@_itemsPerPageRequest = _itemsPerScreen() * 2

# Check if running on mobile
@_isMobile = -> $(window).width() < 760

# -----------------------------------------------------------------------------




