require('./colorsafe')(console)

BOLD = '\x1B[1m'
BLACK = '\x1B[30m'
BLUE = '\x1B[34m'
CYAN = '\x1B[36m'
GREEN = '\x1B[32m'
MAGENTA = '\x1B[35m'
RED = '\x1B[31m'
YELLOW = '\x1B[33m'
RESET = '\x1B[0m'

module.exports =
   mute: false

   log: (msg) ->
      if @mute then return
      console.log msg
   status: (msg) ->
      if @mute then return
      console.log "#{BOLD}#{BLACK}#{msg}#{RESET}"
   dump: (data) ->
      if @mute then return
      console.dir data
   info: (msg) ->
      if @mute then return
      console.info "#{BLUE}#{msg}#{RESET}"
   ok: (msg) ->
      if @mute then return
      console.log "#{GREEN}#{msg}#{RESET}"
   error: (msg) ->
      if @mute then return
      console.error "#{RED}#{msg}#{RESET}"
   warn: (msg) ->
      if @mute then return
      console.warn "#{YELLOW}#{msg}#{RESET}"
   incoming: (msg) ->
      if @mute then return
      console.log "#{CYAN}#{msg}#{RESET}"
   notice: (msg) ->
      if @mute then return
      console.log "#{MAGENTA}#{msg}#{RESET}"
   trace: ->
      if @mute then return
      console.log RED
      console.trace()
      console.log RESET
