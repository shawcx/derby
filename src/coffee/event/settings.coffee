
$        = require('jquery')
_        = require('underscore')
Backbone = require('backbone')


class Item extends Backbone.Model
    idAttribute: 'name'

class Config extends Backbone.Collection
    model: Item
    url: '/config/'

class Ports extends Backbone.Collection
    url: '/serial/'


module.exports.Config = Config
module.exports.Ports  = Ports


class SettingsModal extends Backbone.View
    el: () -> $('#settings-modal')

    events:
        'click #ports-refresh' : 'OnPortRefresh'
        'click #ports-test'    : 'OnPortTest'
        'click #ports-save'    : 'OnPortSave'

    initialize: (options) ->
        @ports  = options.ports
        @config = options.config

        @$tbody = @$('tbody')
        @listenTo @ports, 'add',   @Add, @
        @listenTo @ports, 'reset', (models) =>
            @$tbody.empty()
            models.each (model) =>
                @Add(model)
                return
            item = @config.get('port')
            return if not item
            port = item.get('value')
            $("input[value=\"#{port}\"]").prop('checked', true)
            return
        return @

    Add: (model) ->
        entry = new RowView
            id: "port_row_#{ model.cid }"
            model: model
        @$tbody.append entry.$el
        return

    OnPortRefresh: (event) ->
        @ports.fetch reset:true
        return

    OnPortTest: (event) ->
        value = $('input[name="port"]:checked').val()
        return if not value

        $.ajax
            method: 'POST'
            url: '/serial/test'
            data: value
            success: (data) =>
                console.log 'SUCCESS:', data
                return
        return

    OnPortSave: (event) ->
        value = $('input[name="port"]:checked').val()
        return if not value

        item = @config.get('port')
        item.set value:value
        item.save()
        @$el.modal('hide')
        return


class RowView extends Backbone.View
    tagName: 'tr'
    className: 'settings-port-row'

    events:
        'click'           : 'OnClick'
        'click input'     : 'OnRadioClick'
        'click .portname' : 'OnPortClick'

    initialize: (options) ->
        _.bindAll @, 'render'
        @render()
        @listenTo @model, 'change',  @render
        @listenTo @model, 'remove',  @remove
        @listenTo @model, 'destroy', @remove
        return @

    render: () ->
        isChecked = @$('input[name="port"]').prop('checked')
        model = @model.toJSON()
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

    OnPortClick: (e) ->
        @$('input[name="port"]').prop('checked', true)
        cancelEvent(e)


module.exports.SettingsModal = SettingsModal
