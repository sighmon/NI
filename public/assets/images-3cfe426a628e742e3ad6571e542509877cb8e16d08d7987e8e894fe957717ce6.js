(function(){jQuery(function(){return $(".file-upload").fileupload({dataType:"script",add:function(t,e){var a,n;return n=/(\.|\/)(gif|jpe?g|png)$/i,a=e.files[0],n.test(a.type)||n.test(a.name)?(e.context=$(tmpl("template-upload",a)),$(".file-upload").append(e.context),e.submit()):alert(a.name+" is not a gif, jpeg, or png image file")},progress:function(t,e){var a;if(e.context)return a=parseInt(e.loaded/e.total*100,10),e.context.find(".progress-bar").css("width",a+"%")}}),$("#sortable-block").sortable({update:function(){return $.post($(this).data("update-url"),$(this).sortable("serialize"))}})})}).call(this);