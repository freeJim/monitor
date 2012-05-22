$(document).ready(function(){
        $("#monitor_clear > button").click(function(){
            var $input = $("#monitor_clear input");
            var filename = $input.val();

            if(!confirm("确定要清除这个时段[" + filename + "]的数据吗？"))
                return;
            $.post("/clear/",
                {hour:filename},
                function(data){
                    if(data.success)
                        alert("操作成功");
                    else
                        alert("Failed " + data.text);
                },
                "json");

        });

    //数据上传
    var $element = $(document).find('.file-uploader')[0]; 
    var uploader = new qq.FileUploaderBasic({
        element:$element, 
        action: '/upload/',
        debug:false,
        onSubmit:function(id,filename){
            var str = "<div class='upload_info' fileid='" + id +"'>" + 
                      "<span>0%</span>"+
                      "</div>";
            var $photo = $(str);
            $photo.insertAfter($element);
        },

        onProgress:function(id,filename,loaded,total){
            var key = ".upload_info[fileid=" + id + "]";
            var $photo = $($element).parent().find(key);
            var percent = loaded/total * 100;
            percent = "" + percent + "%";
            $photo.find("span").text(percent);
        },

        onComplete:function(id, filename, data){
            if(data.success){
                var key = ".upload_info[fileid=" + id + "]";
                var $photo = $($element).parent().find(key);
                $photo.remove();
                alert("上传数据成功 " + "文件名:" + data.text);
            }
        }});

    uploader._button = uploader._createUploadButton($element);
        

        $("#monitor_import button").click(function(){
            var $input = $("#monitor_import input");
            var filename = $input.val();

            if(!confirm("确定要导入数据文件[" + filename + "]吗？"))
                return;

            $.post("/import/",
                {filename:filename},
                function(data){
                    if(data.success)
                        alert("成功(导入"+ data.cnt + "条数据)!");
                    else
                        alert("Failed " + data.text);
                },
                "json");
        });

        $("#monitor_top >#top").click(function(){
            $("#monitor_result").children().remove();
            var hour = $(this).parent().find(".top_hour").val();
            

            $.post("/top/",
                {hour:hour},
                function(data){
                    if(data.success){
                        var $tops = $(data.htmls);
                        $("#monitor_result").append($tops);
                    }
                    else
                        alert("Failed");
                },
                "json");
        });

        $("#monitor_top >#retop").click(function(){
            $("#monitor_result").children().remove();
            var hour = $(this).parent().find(".top_hour").val();
            

            $.post("/retop/",
                {hour:hour},
                function(data){
                    if(data.success){
                        var $tops = $(data.htmls);
                        $("#monitor_result").append($tops);
                    }
                    else
                        alert("Failed");
                },
                "json");
        });

        $("#monitor_day >#top_day").click(function(){
            $("#monitor_result").children().remove();
            var day = $(this).parent().find("input").val();
            
            $.post("/topday/",
                {day:day},
                function(data){
                    if(data.success){
                        var $tops = $(data.htmls);
                        $("#monitor_result").append($tops);
                    }
                    else
                        alert("Failed");
                },
                "json");
        });

        $("#monitor_7 >#top_7").click(function(){
            $("#monitor_result").children().remove();
            var day = $(this).parent().find("input").val();
            
            $.post("/top7/",
                {day:day},
                function(data){
                    if(data.success){
                        var $tops = $(data.htmls);
                        $("#monitor_result").append($tops);
                    }
                    else
                        alert("Failed");
                },
                "json");
        });

        $("#monitor_detail >button").click(function(){
            $("#monitor_result").children().remove();
            var hour = $(this).parent().find(".detail_hour").val();
            var ip = $(this).parent().find(".detail_ip").val();
            
            $.post("/detail/",
                {hour:hour,rip:ip},
                function(data){
                    if(data.success){
                        var $tops = $(data.htmls);
                        $("#monitor_result").append($tops);
                    }
                    else
                        alert("Failed");
                },
                "json");
        });
});
