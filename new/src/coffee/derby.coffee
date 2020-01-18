
$        = require('jquery')
_        = require('underscore')
Backbone = require('backbone')
moment   = require('moment')

require('bootstrap')

window.Templates = {}

Events   = require('./events.js')
Event    = require('./event.js')


$(document).ready () ->
    $('script[type="text/html-template"]').each () ->
        name = @id[2..]
        if Templates[name]
            console.log '[-] WARNING: conflicting template name:', name
        Templates[name] = _.template(@text)
        return

    components = window.location.pathname.split('/')
    switch components[1]
        when ''         then new Events.Events
        when 'events'   then new Event.DerbyEvent
    return


window.cancelEvent = (e) ->
    e.preventDefault()
    e.stopPropagation()
    return false
