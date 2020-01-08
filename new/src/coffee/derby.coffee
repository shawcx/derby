
$        = require('jquery')
_        = require('underscore')
Backbone = require('backbone')
moment   = require('moment')

require('bootstrap')

window.Templates = {}

Events   = require('./events.js')
Event    = require('./event.js')
Settings = require('./settings.js')


$(document).ready () ->
    $('script[type="text/html-template"]').each () ->
        name = @id[2..]
        if Templates[name]
            console.log '[-] WARNING: conflicting template name:', name
        Templates[name] = _.template(@text)
        return

    #console.log window.location.pathname
    switch window.location.pathname
        when '/'         then new Events.Events
        when '/event'    then new Event.Derby
        when '/settings' then new Settings.Settings
    return


window.cancelEvent = (e) ->
    e.preventDefault()
    e.stopPropagation()
    return false
