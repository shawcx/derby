
$        = require('jquery')
_        = require('underscore')
Backbone = require('backbone')


class GroupModel extends Backbone.Model
    urlRoot: '/groups/'
    idAttribute: 'group_id'


class GroupCollection extends Backbone.Collection
    model: GroupModel
    url: () -> "/groups/#{ event_id }"


module.exports.Model      = GroupModel
module.exports.Collection = GroupCollection


class GroupsModal extends Backbone.View
    el: () -> $('#groups-modal')

    events:
        'click #groups-add-group' : 'OnAddGroup'

    initialize: (options) ->
        @groupsTable = new GroupsTable
            collection: options.groups
        @render()
        return @

    render: () ->
        return @

    reset: () ->
        return

    OnAddGroup: () ->
        group = new GroupModel
            event_id: event_id
            group: ''
        @groupsTable.Add group
        return


module.exports.GroupsModal = GroupsModal


class GroupsTable extends Backbone.View
    el: () -> $('#groups-table')

    initialize: (options) ->
        @rows   = {}
        @$tbody = @$('tbody')

        # bind to the groups collection
        @listenTo @collection, 'add', @Add, @
        @listenTo @collection, 'reset', (groups) =>
            groups.forEach @Add, @
            return
        return @

    Add: (group) ->
        groupRow = new GroupsRow
            collection: @collection
            model: group
        @rows[group.id] = groupRow
        @$tbody.append groupRow.$el
        return


class GroupsRow extends Backbone.View
    tagName: 'tr'
    className: 'groupRow'

    events:
        'click .group-save'   : 'OnSave'
        'click .group-delete' : 'OnDelete'

    initialize: () ->
        _.bindAll @, 'render'
        @render()
        @listenTo @model, 'change',  @render, @
        @listenTo @model, 'remove',  @remove, @
        @listenTo @model, 'destroy', @remove, @
        return @

    render: () ->
        @$el.html Templates['group-row'] @model.toJSON()
        return @

    OnSave: () ->
        groupName = @$('input.add-group-group').val()
        return if not groupName

        hasId = @model.id?
        @model.save group: groupName,
            wait: true
            success: (model) =>
                if not hasId
                    @remove()
                    @collection.add model
                return
            error: (msg) =>
                @$('input.add-group-group').addClass('bg-danger')
                return
        return

    OnDelete: () ->
        really = confirm("Remove #{ @model.get('group') }?")
        return if not really
        @model.destroy wait: true
        return
