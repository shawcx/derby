
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

        @groups.on 'remove', (groupModel) =>
            racer_ids = []
            @racers.forEach (racerModel) =>
                if racerModel.get('group_id') is groupModel.id
                    racer_ids.push racerModel.id
                return
            @racers.remove racer_ids
            return

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
        @dispatch.on 'groups',      @OnGroups,      @
        @dispatch.on 'groupRemove', @OnGroupRemove, @
        @dispatch.on 'racers',      @OnRacers,      @
        @dispatch.on 'racerRemove', @OnRacerRemove, @
        @dispatch.on 'raceResults', @OnRaceResults, @

        promises = []
        promises.push @config.fetch reset:true
        promises.push @ports.fetch  reset:true
        promises.push @groups.fetch reset:true

        Promise.all(promises).then () =>
            promises = []
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
                        #console.log bundle.action, bundle.message
                        @dispatch.trigger(bundle.action, bundle.message)
                        return
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

    OnGroups: (message) ->
        group = @groups.get(message.group_id)
        if not group
            @groups.add message
        else
            group.set message
        return

    OnGroupRemove: (message) ->
        @groups.remove(message)
        if @groups.length is 0
            $('tr.no-groups').removeClass('d-none')
            $('tr.no-racers').addClass('d-none')
        return

    OnRacers: (message) ->
        racer = @racers.get(message.racer_id)
        if not racer
            @racers.add message
        else
            racer.set message
        return

    OnRacerRemove: (message) ->
        @racers.remove(message)
        $('tr.no-racers').removeClass('d-none') if @racers.length is 0
        return

    OnRaceResults: (message) ->
        @heatModal.results(message.A, message.B)
        return

    resizer: () ->
        w = $(document).width()
        h = $(document).height()
        return

module.exports.DerbyEvent = DerbyEvent
