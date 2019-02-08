
$        = require('jquery')
_        = require('underscore')
Backbone = require('backbone')
moment   = require('moment')

require('bootstrap')

window.Templates = {}

Racers  = require('./racers.js')
Times   = require('./times.js')
Heat    = require('./heat.js')
Results = require('./results.js')
Socket  = require('./socket.js')


$(document).ready () ->
    $('script[type="text/html-template"]').each () ->
        name = @id[2..]
        if Templates[name]
            console.log '[-] WARNING: conflicting template name:', name
        Templates[name] = _.template(@text)
        return
    new Derby
    return


class Derby
    constructor: () ->
        @racers = new Racers.Collection
        @times  = new Times.Collection

        window.t = @times
        new Racers.AddRacerModal
            collection: @racers

        new Racers.RacersModal
            collection: @racers

        @heatModal = new Heat.HeatModal
            collection: @racers

        new Results.ResultsTable
            collection: @racers

        window.p = (a,b) =>
            @heatModal.results(a,b)
            return null

        @dispatch = _.clone(Backbone.Events)
        @dispatch.on 'connected',   @OnConnected,   @
        @dispatch.on 'trackState',  @OnTrackState,  @
        @dispatch.on 'raceResults', @OnRaceResults, @

        promises = []
        promises.push @racers.fetch  reset:true
        promises.push @times.fetch   reset:true

        Promise.all(promises).then () =>
            @times.forEach (timeModel) =>
                entry = timeModel.toJSON()
                entry.time = parseFloat(entry.time)
                racer = @racers.get(entry.racer_id)

                count = racer.get('count')
                count += 1
                update = {}
                update['time'+count] = entry.time.toFixed(4)
                update['lane'+count] = entry.lane
                update['count'] = count
                racer.set update

                #console.log entry.racer_id, entry.lane, entry.time
                return

            @socket = new Socket
                onmessage: (bundle) =>
                    #console.log 'WS:', bundle.action, bundle.message
                    @dispatch.trigger(bundle.action, bundle.message)
                    return
            return
        return

    # called after the websocket is successfully connected
    # sends current track state
    OnConnected: (message) ->
        @heatModal.gate(message.gateClosed)

# dev -------------------------------
        #$('#heat-modal').modal()
        #@heatModal.selectA.set(3)
        #@heatModal.selectB.set(4)
# -----------------------------------
        return

    OnTrackState: (message) ->
        @heatModal.gate(message.gateClosed)
        return

    OnRaceResults: (message) ->
        @heatModal.results(message.A, message.B)
        return

    resizer: () ->
        w = $(document).width()
        h = $(document).height()
        return


@$SVG = (name) -> $ document.createElementNS('http://www.w3.org/2000/svg', name)


window.cancelEvent = (e) ->
    e.preventDefault()
    e.stopPropagation()
    return false
