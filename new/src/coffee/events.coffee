
$        = require('jquery')
_        = require('underscore')
Backbone = require('backbone')


class EventsModel extends Backbone.Model
    urlRoot: '/events/'
    idAttribute: 'event_id'


class EventsCollection extends Backbone.Collection
    model: EventsModel
    url: EventsModel.prototype.urlRoot


class Events
    constructor: () ->
        @events = new EventsCollection

        new AddEventModal
            collection: @events

        @eventsTable = new EventsTable
            collection: @events

        promises = []
        promises.push @events.fetch  reset:true

        Promise.all(promises).then () =>
            return
        return


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
        return

    OnShowModal: () ->
        return

    OnHideModal: () ->
        return

    OnEventSave: (evt) ->
        @event.save {
                event: $('#add-event-name').val()
                date:  $('#add-event-date').val()
            },{
                wait: true,
                success: () =>
                    @collection.add @event
                    @reset()
                    @$el.modal('hide')
                    return
                error: (model,xhr) =>
                    alert(xhr.responseText)
                    return
            }
        return cancelEvent(evt)


class EventsTable extends Backbone.View
    el: () -> $('#events-table')

    initialize: (options) ->
        @$tbody = @$('tbody')

        # bind to the racers collection
        @listenTo @collection, 'add', @Add, @
        @listenTo @collection, 'reset', (racers) =>
            racers.forEach @Add, @
            return
        return @

    Add: (event) ->
        eventRow = new EventsRow
            model: event
        @$tbody.append eventRow.$el
        return


class EventsRow extends Backbone.View
    tagName: 'tr'
    className: 'eventRow'
    events:
        'click .delete-event' : 'OnDeleteEvent'

    initialize: () ->
        _.bindAll @, 'render'
        @render()
        @listenTo @model, 'change',  @render, @
        @listenTo @model, 'remove',  @remove, @
        @listenTo @model, 'destroy', @remove, @
        return @

    render: () ->
        @$el.html Templates['event-row'] @model.toJSON()
        return @

    OnDeleteEvent: (evt) ->
        really = confirm("Remove #{ @model.get('event') }?")
        return if not really
        @model.destroy wait: true
        return


module.exports.Events        = Events
module.exports.Model         = EventsModel
module.exports.Collection    = EventsCollection
module.exports.AddEventModal = AddEventModal
