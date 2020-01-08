
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
                name: $('#add-event-name').val()
                date: $('#add-event-date').val()
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
        @rows   = {}
        @$tbody = @$('tbody')

        # bind to the racers collection
        @listenTo @collection, 'add', @Add, @
        @listenTo @collection, 'reset', (racers) =>
            racers.forEach @Add, @
            return
        @listenTo @collection, 'sort', (racers) =>
            racers.forEach (racer) =>
                row = @rows[racer.id]
                row.$el.remove()
                @$tbody.append(row.$el)
                return
            return
        return @

    Add: (racer) ->
        eventRow = new EventsRow
            model: racer
        @rows[racer.id] = eventRow
        @$tbody.append eventRow.$el
        return


class EventsRow extends Backbone.View
    tagName: 'tr'
    className: 'eventRow'

    initialize: () ->
        _.bindAll @, 'render'
        @render()
        @listenTo @model, 'change',  @render, @
        @listenTo @model, 'remove',  @remove, @
        @listenTo @model, 'destroy', @remove, @
        return @

    render: () ->
        model = @model.toJSON()

        model.time1='💥' if model.time1 == '0.0000'
        model.time2='💥' if model.time2 == '0.0000'
        model.time3='💥' if model.time3 == '0.0000'
        model.time4='💥' if model.time4 == '0.0000'

        model.time1 = '-.----' if model.time1 == ''
        model.time2 = '-.----' if model.time2 == ''
        model.time3 = '-.----' if model.time3 == ''
        model.time4 = '-.----' if model.time4 == ''

        model.lane1 = '-' if model.lane1 == ''
        model.lane2 = '-' if model.lane2 == ''
        model.lane3 = '-' if model.lane3 == ''
        model.lane4 = '-' if model.lane4 == ''

        @$el.html Templates['event-row'] model

        if @model.get('count') == 4
            worse = @model.calculateTotal()
            worse = worse.toFixed(4)
            if worse == '10.0000'
                worse = '💥'

            for el,idx in @$el.find('.td-times')
                break if idx is 4
                if $(el).text().startsWith(worse)
                    $(el).css('opacity', '0.5').css('text-decoration', 'line-through')
                    break

        return @


module.exports.Events        = Events
module.exports.Model         = EventsModel
module.exports.Collection    = EventsCollection
module.exports.AddEventModal = AddEventModal
