
$        = require('jquery')
_        = require('underscore')
Backbone = require('backbone')

class AddRacerModal extends Backbone.View
    el: () -> $('#add-racer-modal')

    events:
        'show.bs.modal' : 'OnShowModal'
        'click video'   : 'OnClickVideo'

    OnShowModal: () ->
        constraints =
            video: true
        #  video:
        #    width:
        #      min: 1280
        #    height:
        #        min: 720

        video = @$('video')

        navigator.mediaDevices.getUserMedia(constraints).then (stream) =>
            video[0].srcObject = stream
            return
        return

    OnClickVideo: () ->
        constraints =
          video:
            width:
              min: 320
            height:
                min: 240

        video = document.querySelector('video');

        DIMENSIONS = 240

        canvas = document.createElement('canvas');
        canvas.width  = DIMENSIONS
        canvas.height = DIMENSIONS

        offset = (video.videoWidth - video.videoHeight)

        #navigator.mediaDevices.getUserMedia(constraints).then(handleSuccess).catch(handleError)
        canvas.getContext('2d').drawImage(
            video,
            offset, 0,
            video.videoHeight, video.videoHeight,
            0, 0,
            DIMENSIONS, DIMENSIONS
            );

        $('#avatarImg').attr('src', canvas.toDataURL('image/png')).css('display','block')
        $('#avatarVid').hide()

        #handleSuccess = (stream) ->
        #    #screenshotButton.disabled = false
        #    video.srcObject = stream
        #    return

        return


module.exports.AddRacerModal = AddRacerModal
#module.exports.Collection = Collection
#module.exports.PanelView  = PanelView
