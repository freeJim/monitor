$(document).ready(function(){
        $("#monitor_clear").click(function(){
            $.post("/clear/",
                function(data){
                    if(data.success)
                        alert("操作成功");
                    else
                        alert("Failed");
                },
                "json");

        });

        $("#monitor_import button").click(function(){
            var $input = $("#monitor_import input");
            console.log("xxx");
            var filename = $input.val();
            $.post("/import/",
                {filename:filename},
                function(data){
                    if(data.success)
                        alert("成功(导入"+ data.cnt + "条数据)!");
                    else
                        alert("Failed");
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
