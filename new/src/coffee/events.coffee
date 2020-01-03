
$        = require('jquery')
_        = require('underscore')
Backbone = require('backbone')


class EventsModel extends Backbone.Model
    urlRoot: '/racers/'
    idAttribute: 'racer_id'

class EventsCollection extends Backbone.Collection
    model: EventsModel
    url: EventsModel.prototype.urlRoot

module.exports.Model      = EventsModel
module.exports.Collection = EventsCollection

class Events
    constructor: () ->
        @events = new EventsCollection

        new AddEventModal
            collection: @events

        #new Events.EventModal
        #    collection: @events

        #@resultsTable = new Results.ResultsTable
        #    collection: @events

        @dispatch = _.clone(Backbone.Events)
        @dispatch.on 'connected',   @OnConnected,   @
        @dispatch.on 'trackState',  @OnTrackState,  @

        promises = []
        promises.push @events.fetch  reset:true

        Promise.all(promises).then () =>
            #@socket = new Socket
            #    onmessage: (bundle) =>
            #        @dispatch.trigger(bundle.action, bundle.message)
            #        return
            return
        return

    # called after the websocket is successfully connected
    # sends current track state
    OnConnected: (message) ->
        #if message.gateClosed is null
        #    alert('Serial interface not connected')
# dev -------------------------------
        #$('#heat-modal').modal()
        #@heatModal.selectA.set(1)
        #@heatModal.selectB.set(2)
# -----------------------------------
        return

    OnTrackState: (message) ->
        @heatModal.gate(message.gateClosed)
        return

module.exports.Events = Events


class AddEventModal extends Backbone.View
    el: () -> $('#add-event-modal')

    events:
        'show.bs.modal'          : 'OnShowModal'
        'hide.bs.modal'          : 'OnHideModal'
        'submit form'            : 'OnEventSave'
        'click #add-event-reset' : 'reset'

    initialize: (options) ->
        @reset()
        return @

    reset: () ->
        @event = new EventsModel
        $('#add-event-name').val('')
        $('#add-event-date').val('')
        $('#add-event-save').prop('disabled', true)
        return

    OnShowModal: () ->
        @vidSize = $('#avatarVid').height()
        if not @stream
            constraints =
                video: true
            @video = document.querySelector('video')
            navigator.mediaDevices.getUserMedia(constraints).then (stream) =>
                @video.srcObject = @stream = stream
                return
        return

    OnHideModal: () ->
        return if not @stream
        for track in @stream.getTracks()
            track.stop()
        @stream = null
        return

    OnEventSave: (evt) ->
        @event.save {
                name:  $('#add-event-name').val()
                group: $('#add-event-group').val()
                date:   $('#add-event-date').val()
            },{
                wait: true,
                success: () =>
                    @collection.add @event
                    @reset()
                    return
                error: (model,xhr) =>
                    alert(xhr.responseText)
                    return
            }
        return cancelEvent(evt)

module.exports.AddEventModal = AddEventModal
