
$        = require('jquery')
_        = require('underscore')
Backbone = require('backbone')

class RacerModel extends Backbone.Model
    urlRoot: '/data/racers/'
    idAttribute: 'racer_id'

class RacerCollection extends Backbone.Collection
    model: RacerModel

module.exports.Model      = RacerModel
module.exports.Collection = RacerCollection


class AddRacerModal extends Backbone.View
    el: () -> $('#add-racer-modal')

    events:
        'show.bs.modal'         : 'OnShowModal'
        #'click #add-racer-save' : 'OnRacerSave'
        'submit form'           : 'OnRacerSave'
        'click #avatarVid'      : 'OnClickVideo'
        'click #avatarImg'      : 'OnClickImage'

    initialize: (options) ->
        @reset()
        console.log 'O:', options
        console.log 'C:', @collection
        return @

    reset: () ->
        @racer = new RacerModel
        $('#add-racer-name').val('')
        #$('#add-racer-den').val('')
        $('#add-racer-car').val('')
        return

    OnShowModal: () ->
        @vidSize = $('#avatarVid').height()
        if not @video
            constraints =
                video: true
            @video = document.querySelector('video')
            navigator.mediaDevices.getUserMedia(constraints).then (stream) =>
                @video.srcObject = stream
                return
        return

    OnRacerSave: (evt) ->
        if not @racer.has('avatar')
            console.log 'no avatar...'
        @racer.save {
                name: $('#add-racer-name').val()
                den:  $('#add-racer-den').val()
                car:  $('#add-racer-car').val()
            },{
                wait: true,
                success: () =>
                    console.log 'ZZZ:', @racer
                    console.log 'ZZZ:', @collection
                    @collection.add @racer
                    @reset()
                    return
            }
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
            @video.videoHeight,                     # src width (using height prop for square)
            @video.videoHeight,                     # src height
            0,                                      # dst offset x
            0,                                      # dst offset y
            @vidSize,                               # dst width
            @vidSize                                # dst height
            )

        avatar = canvas.toDataURL('image/jpeg', 0.9)
        @racer.set('avatar', avatar)
        $('#avatarImg').attr('src', avatar).show()
        $('#avatarVid').hide()
        return

    OnClickImage: () ->
        $('#avatarImg').hide()
        $('#avatarVid').show()
        @racer.unset('avatar')


module.exports.AddRacerModal = AddRacerModal
