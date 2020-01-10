
$        = require('jquery')
_        = require('underscore')
Backbone = require('backbone')

Groups  = require('./event/groups.js')
Racers  = require('./event/racers.js')
Times   = require('./event/times.js')
Heat    = require('./event/heat.js')
Results = require('./event/results.js')
Socket  = require('./socket.js')


class DerbyEvent
    constructor: () ->
        #window._eventName = decodeURIComponent window.location.hash[1..]
        #$('#event-name').text window._eventName

        @groups = new Groups.Collection
            event_id : event_id
        @racers = new Racers.Collection
        @times  = new Times.Collection

        new Groups.GroupsModal
            collection: @groups

        new Racers.AddRacerModal
            collection: @racers

        new Racers.RacerModal
            collection: @racers

        @heatModal = new Heat.HeatModal
            collection: @racers

        @resultsTable = new Results.ResultsTable
            collection: @racers
            groups: @groups

#        window.p = (a,b) =>
#            @heatModal.results(a,b)
#            return null
#
#        window.pp = (base) =>
#            a = Math.random() + base
#            b = Math.random() + base
#            @heatModal.results(a,b)
#            return null

        @dispatch = _.clone(Backbone.Events)
        @dispatch.on 'connected',   @OnConnected,   @
        @dispatch.on 'trackState',  @OnTrackState,  @
        @dispatch.on 'raceResults', @OnRaceResults, @

        promises = []
        promises.push @groups.fetch reset:true
        promises.push @racers.fetch reset:true
        promises.push @times.fetch  reset:true

        Promise.all(promises).then () =>
            @times.forEach (timeModel) =>
                entry = timeModel.toJSON()
                entry.time = parseFloat(entry.time)
                racer = @racers.get(entry.racer_id)
                return if not racer
                count = racer.get('count')
                count += 1
                update = {}
                update['time'+count] = entry.time.toFixed(4)
                update['lane'+count] = entry.lane
                update['count'] = count
                racer.set update
                racer.calculateTotal()
                return

            @racers.sort()

            @socket = new Socket
                onmessage: (bundle) =>
                    @dispatch.trigger(bundle.action, bundle.message)
                    return
            return
        return

    # called after the websocket is successfully connected
    # sends current track state
    OnConnected: (message) ->
        #if message.gateClosed is null
        #    alert('Serial interface not connected')
        @heatModal.gate(message.gateClosed)

# dev -------------------------------
        #$('#groups-modal').modal()
        #@heatModal.selectA.set(1)
        #@heatModal.selectB.set(2)
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

module.exports.DerbyEvent = DerbyEvent
