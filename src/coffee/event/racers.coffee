
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
            time = parseFloat(@get('time'+idx))
            if time == 0
                times.push(10)
            else if time
                times.push(time)
            # else ignore

        sortNumber = (a, b) -> a - b
        times.sort(sortNumber)
        worst = times[3]
        times = times.slice(0,3)

        sumNumber = (a, b) -> a + b
        total = times.reduce(sumNumber, 0) / times.length
        @set('total', total.toFixed(4))
        return worst


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
        @racers = options.racers
        @groups = options.groups
        return @

    OnShowModal: (evt) ->
        @racer = @racers.get $(evt.relatedTarget).data('racer')
        model = @racer.toJSON()
        @$('img.avatar').attr 'src', model.avatar
        @$('#race-modal-racer').text model.racer
        @$('#race-modal-group').text @groups.get(model.group_id).get('group')
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
        'shown.bs.modal'         : 'OnShownModal'
        'hide.bs.modal'          : 'OnHideModal'
        'submit form'            : 'OnRacerSave'
        'click #add-racer-reset' : 'reset'
        'click #avatarVid'       : 'OnClickVideo'
        'click #avatarVid'       : 'OnClickVideo'
        'click #avatarImg'       : 'OnClickImage'

    initialize: (options) ->
        @racers = options.racers
        @groups = options.groups

        @reset()
        @listenTo @groups, 'add', @AddGroup, @
        @listenTo @groups, 'reset', (groups) =>
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
        $('#add-racer-save').prop('disabled', true).removeClass('btn-primary').addClass('btn-secondary')

        return

    OnShowModal: (evt) ->
        @reset()

        @vidSize = $('#avatarVid').height()
        if not @stream
            constraints =
                video: true
            @video = document.querySelector('video')
            navigator.mediaDevices.getUserMedia(constraints)
                .then (stream) =>
                    @video.srcObject = @stream = stream
                    return
                .catch (error) =>
                    alert('Could not access camera!')
                    return
        return

    OnShownModal: (evt) ->
        if @groups.length is 0
            alert('Please add group first!')


    OnHideModal: () ->
        return if not @stream
        for track in @stream.getTracks()
            track.stop()
        @stream = null
        return

    OnRacerSave: (evt) ->
        if not @racer.has('avatar')
            alert('No picture was taken')
            return cancelEvent(evt)
        @racer.save
            event_id: event_id
            group_id: parseInt($('#add-racer-group').val())
            racer:    $('#add-racer-racer').val()
            car:      $('#add-racer-car').val()
          ,
            wait: true,
            success: (m) =>
                @racers.add @racer
                @reset()
                return
            error: (model,xhr) =>
                alert(xhr.responseText)
                return
        return cancelEvent(evt)

    OnClickVideo: () ->
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

        avatar = canvas.toDataURL('image/jpeg', 1.0)
        @racer.set('avatar', avatar)
        $('#avatarVid').hide()
        $('#avatarImg').attr('src', avatar).show()
        $('#add-racer-save').prop('disabled', false).removeClass('btn-secondary').addClass('btn-primary')

        return

    OnClickImage: () ->
        $('#avatarImg').hide()
        $('#avatarVid').show()
        $('#add-racer-save').prop('disabled', true).removeClass('btn-primary').addClass('btn-secondary')

        @racer.unset('avatar')
        return


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
