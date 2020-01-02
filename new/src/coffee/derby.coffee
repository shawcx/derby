
$        = require('jquery')
_        = require('underscore')
Backbone = require('backbone')
moment   = require('moment')

require('bootstrap')

window.Templates = {}

Derby    = require('./event.js')
Settings = require('./settings.js')


$(document).ready () ->
    $('script[type="text/html-template"]').each () ->
        name = @id[2..]
        if Templates[name]
            console.log '[-] WARNING: conflicting template name:', name
        Templates[name] = _.template(@text)
        return

    switch window.location.pathname
        when '/settings' then new Settings.Settings
        when '/event'    then new Derby.Derby
    return

@$SVG = (name) -> $ document.createElementNS('http://www.w3.org/2000/svg', name)

window.cancelEvent = (e) ->
    e.preventDefault()
    e.stopPropagation()
    return false
