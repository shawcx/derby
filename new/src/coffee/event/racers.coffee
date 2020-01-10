
$        = require('jquery')
_        = require('underscore')
Backbone = require('backbone')

class RacerModel extends Backbone.Model
    urlRoot: '/racers/'
    idAttribute: 'racer_id'
    defaults:
        count: 0
        time1: ''
        time2: ''
        time3: ''
        time4: ''
        lane1: ''
        lane2: ''
        lane3: ''
        lane4: ''
        total: ''

    calculateTotal: () ->
        times = []
        for idx in [1..4]
            t = @get('time'+idx)
            t = parseFloat(t)
            if t == 0
                times.push(10)
            else if t
                times.push(t)
            # else ignore

        sortNumber = (a, b) -> a - b
        times.sort(sortNumber)
        worse = times[3]
        times = times.slice(0,3)

        sumNumber = (a, b) -> a + b
        total = times.reduce(sumNumber, 0) / times.length
        @set('total', total.toFixed(4))
        return worse


class RacerCollection extends Backbone.Collection
    model: RacerModel
    url: () -> "/racers/#{ event_id }"
    comparator: (a,b) ->
        aTotal = a.get('total')
        bTotal = b.get('total')
        aTotal = if aTotal then parseFloat(aTotal) else Infinity
        bTotal = if bTotal then parseFloat(bTotal) else Infinity
        return aTotal - bTotal

module.exports.Model      = RacerModel
module.exports.Collection = RacerCollection


class RacerModal extends Backbone.View
    el: () -> $('#racer-modal')

    events:
        'show.bs.modal'        : 'OnShowModal'
        'click #save-racer'    : 'OnSave'
        'click #delete-racer'  : 'OnDelete'

    initialize: (options) ->
        return @

    OnShowModal: (evt) ->
        @racer = @collection.get $(evt.relatedTarget).data('racer')
        model = @racer.toJSON()
        @$('img.avatar').attr 'src', model.avatar
        @$('#race-modal-racer').text model.racer
        @$('#race-modal-group').text model.group
        @$('#race-modal-car'  ).text model.car
        return

    OnSave: () ->
        @racer.save
            racer: @$('#race-modal-racer').text()
            car:   @$('#race-modal-car').text()
          ,
            wait: true
            error: (model,xhr) =>
                @$('#race-modal-racer').addClass('border border-danger bg-danger text-light rounded')
                #alert(xhr.responseText)
                return
        return

    OnDelete: () ->
        really = confirm("Remove #{ @racer.get('racer') }?")
        return if not really
        @racer.destroy wait: true
        @$el.modal('hide')
        return

module.exports.RacerModal = RacerModal


class AddRacerModal extends Backbone.View
    el: () -> $('#add-racer-modal')

    events:
        'show.bs.modal'          : 'OnShowModal'
        'hide.bs.modal'          : 'OnHideModal'
        'submit form'            : 'OnRacerSave'
        'click #add-racer-reset' : 'reset'
        'click #avatarVid'       : 'OnClickVideo'
        'click #avatarVid'       : 'OnClickVideo'
        'click #avatarImg'       : 'OnClickImage'

    initialize: (options) ->
        @reset()
        @listenTo @collection.groups, 'add', @AddGroup, @
        @listenTo @collection.groups, 'reset', (groups) =>
            groups.forEach @AddGroup, @
            return
        return @

    AddGroup: (group) ->
        groupOption = new GroupOption
            model: group
        @$('#add-racer-group').append groupOption.$el
        return

    reset: () ->
        @racer = new RacerModel

        $('#add-racer-racer').val('')
        $('#add-racer-group').val(null)
        $('#add-racer-car').val('')

        $('#avatarImg').hide()
        $('#avatarVid').show()
        $('#add-racer-save').prop('disabled', true)

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

    OnRacerSave: (evt) ->
        if not @racer.has('avatar')
            alert('No picture was taken')
            return cancelEvent(evt)
        @racer.save
            event_id: event_id
            group_id: $('#add-racer-group').val()
            racer:    $('#add-racer-racer').val()
            car:      $('#add-racer-car').val()
          ,
            wait: true,
            success: () =>
                @collection.add @racer
                @reset()
                return
            error: (model,xhr) =>
                alert(xhr.responseText)
                return
        return cancelEvent(evt)

    OnClickVideo: () ->
        constraints =
          video:
            width:
              min: 320
            height:
                min: 240

        canvas = document.createElement('canvas')
        canvas.width  = @vidSize
        canvas.height = @vidSize
        canvas.getContext('2d').drawImage(
            @video,                                 # src
            @video.videoWidth - @video.videoHeight, # src offset x
            0,                                      # src offset y
            @video.videoHeight,                     # src width (use height for square)
            @video.videoHeight,                     # src height
            0,                                      # dst offset x
            0,                                      # dst offset y
            @vidSize,                               # dst width
            @vidSize                                # dst height
            )

        avatar = canvas.toDataURL('image/jpeg', 0.9)
        @racer.set('avatar', avatar)
        $('#avatarVid').hide()
        $('#avatarImg').attr('src', avatar).show()
        $('#add-racer-save').prop('disabled', false)
        return

    OnClickImage: () ->
        $('#avatarImg').hide()
        $('#avatarVid').show()
        $('#add-racer-save').prop('disabled', true)
        @racer.unset('avatar')


class GroupOption extends Backbone.View
    tagName: 'option'

    initialize: (options) ->
        @$el.attr('value', @model.id)
        @render()
        @listenTo @model, 'change',  @render, @
        @listenTo @model, 'remove',  @remove, @
        @listenTo @model, 'destroy', @remove, @
        return @

    render: () ->
        @$el.text @model.get('group')
        return @

module.exports.AddRacerModal = AddRacerModal
