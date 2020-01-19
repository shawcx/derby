
$        = require('jquery')
_        = require('underscore')
Backbone = require('backbone')

Groups   = require('./event/groups.js')
Racers   = require('./event/racers.js')
Times    = require('./event/times.js')
Heat     = require('./event/heat.js')
Results  = require('./event/results.js')
Settings = require('./event/settings.js')
Socket   = require('./socket.js')


class DerbyEvent
    constructor: () ->
        #window._eventName = decodeURIComponent window.location.hash[1..]
        #$('#event-name').text window._eventName

        @groups = new Groups.Collection
        @racers = new Racers.Collection
        @times  = new Times.Collection
        @config = new Settings.Config()
        @ports  = new Settings.Ports()

        @groups.on 'destroy', (groupModel) =>
            console.log 'main destroy', groupModel
            racer_ids = []
            @racers.forEach (racerModel) =>
                if racerModel.get('group_id') is groupModel.id
                    racer_ids.push racerModel.id
                #console.log JSON.stringify racerModel.toJSON()
                return
            console.log racer_ids
            @racers.remove racer_ids
            return

        new Groups.GroupsModal
            groups: @groups

        new Racers.AddRacerModal
            racers: @racers
            groups: @groups

        new Racers.RacerModal
            racers: @racers
            groups: @groups

        new Settings.SettingsModal
            config: @config
            ports:  @ports

        @heatModal = new Heat.HeatModal
            racers: @racers
            groups: @groups

        @resultsTable = new Results.ResultsTable
            racers: @racers
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
        @dispatch.on 'trackState',  @OnTrackState,  @
        @dispatch.on 'raceResults', @OnRaceResults, @

        promises = []
        promises.push @groups.fetch reset:true
        promises.push @racers.fetch reset:true
        promises.push @times.fetch  reset:true
        promises.push @config.fetch reset:true
        promises.push @ports.fetch  reset:true

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
                    #console.log bundle.action, bundle.message
                    @dispatch.trigger(bundle.action, bundle.message)
                    return
            return
        return

    OnTrackState: (message) ->
        if message.portOpen
            $('#tr-status').addClass('d-none')
        else
            $('#tr-status').removeClass('d-none')

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
