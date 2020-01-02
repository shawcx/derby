
$        = require('jquery')
_        = require('underscore')
Backbone = require('backbone')


class Model extends Backbone.Model
    idAttribute: 'settings_id'
    urlRoot: '/data/settings/'


class Collection extends Backbone.Collection
    model: Model
    url: Model.prototype.urlRoot


module.exports.Model      = Model
module.exports.Collection = Collection


class Settings
    constructor: () ->
        @ports = new Backbone.Collection()

        new PanelView
            collection: @ports

        $.ajax
            method: 'GET'
            url: '/serial'
            success: (data) =>
                for port in data.ports
                    @ports.add port:port
                return

class PanelView extends Backbone.View
    el: () -> $('#settings-ports')

    events:
        'click #settings-ports-form-save' : 'OnSaveUser'

    initialize: (@options) ->
        @$tbody = @$('tbody')
        @listenTo @collection, 'add',   @Add, @
        @listenTo @collection, 'reset', (models) =>
            @$tbody.empty()
            models.each (model) =>
                @Add(model)
                return
            return
        return @

    Add: (model) ->
        entry = new RowView
            id: "port_row_#{ model.cid }"
            model: model
        @$tbody.append entry.$el
        return

    OnSaveUser: (event) ->
        return


class RowView extends Backbone.View
    tagName: 'tr'
    className: 'settings-port-row'

    events:
        'click'           : 'OnClick'
        'click input'     : 'OnRadioClick'
        'click .portname' : 'OnUserClick'

    initialize: (@options) ->
        _.bindAll @, 'render'
        @render()
        @listenTo @model, 'change',  @render
        @listenTo @model, 'remove',  @remove
        @listenTo @model, 'destroy', @remove
        return @

    render: () ->
        isChecked = @$('input[name="port"]').prop('checked')
        model = @model.toJSON()
        console.log model
        @$el.html Templates['port-row'] model
        @$('input[name="port"]').prop('checked', isChecked)
        return

    OnClick: () ->
        $radio = @$('input[name="port"]')
        value = $radio.prop('checked')
        $radio.prop('checked', not value)
        return

    OnRadioClick: (e) ->
        e.stopPropagation()
        return

    OnUserClick: (e) ->
        @$('input[name="port"]').prop('checked', true)
        cancelEvent(e)


module.exports.Settings = Settings