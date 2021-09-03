(function() {
  jQuery(function() {
    $('.file-upload').fileupload({
      dataType: "script",
      add: function(e, data) {
        var file, types;
        types = /(\.|\/)(gif|jpe?g|png)$/i;
        file = data.files[0];
        if (types.test(file.type) || types.test(file.name)) {
          data.context = $(tmpl("template-upload", file));
          $('.file-upload').append(data.context);
          return data.submit();
        } else {
          return alert(file.name + " is not a gif, jpeg, or png image file");
        }
      },
      progress: function(e, data) {
        var progress;
        if (data.context) {
          progress = parseInt(data.loaded / data.total * 100, 10);
          return data.context.find('.progress-bar').css('width', progress + '%');
        }
      }
    });
    return $('#sortable-block').sortable({
      update: function() {
        return $.post($(this).data('update-url'), $(this).sortable('serialize'));
      }
    });
  });

}).call(this);
