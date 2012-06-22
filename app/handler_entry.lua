require 'bamboo'
Access = require 'models.access'
AccessHour = require 'models.accessHour'
IpCnt = require 'models.ipcnt'
Util = require 'app.util'
Upload = require 'bamboo.models.upload'
Top = require 'app.top'

bamboo.registerModel(require 'models.access')
bamboo.registerModel(require 'models.accessHour')
bamboo.registerModel(require 'models.ipcnt')
bamboo.registerModule(require 'app.util')
bamboo.registerModule(require 'app.top')

local View = require 'bamboo.view'

local function index(web, req)
    web:page(View("index.html"){})

end

local function import(web,req)
    local filename = req.PARAMS.filename;
    local success, cnt = Top.import_data(filename);
    if success then
        web:json{ success=true, cnt=cnt }
    else
        web:json{ success=false, text=cnt }
    end

end

local function clear(web,req)
    local hour = req.PARAMS.hour;
    hour = Util.timeStr2Struct(hour);
    
    local success, text = Top.hour_clear(hour);

    if success then
        web:json{ success=true }
    else
        web:json{ success=false, text=text }
    end
end

local function top(web, req)
    local hour = req.PARAMS.hour;
    hour = Util.timeStr2Struct(hour);

    local top,total,ipnum = Top.top_hour(hour);
    
    local startTime = string.format("%d-%d-%d %d:00:00",hour.year,hour.month,hour.day,hour.hour);
    local endTime = string.format("%d-%d-%d %d:59:59",hour.year,hour.month,hour.day,hour.hour);

    web:json{
        success = true,
        htmls = View("top.html"){"locals"},
    };
end

local function retop(web, req)
    local hour = req.PARAMS.hour;
    hour = Util.timeStr2Struct(hour);

    local top,total,ipnum = Top.retop_hour(hour);
    
    local startTime = string.format("%d-%d-%d %d:00:00",hour.year,hour.month,hour.day,hour.hour);
    local endTime = string.format("%d-%d-%d %d:59:59",hour.year,hour.month,hour.day,hour.hour);

    web:json{
        success = true,
        htmls = View("top.html"){"locals"},
    };
end

local  function topday(web,req)
    local day = req.PARAMS.day;
    day = Util.timeStr2Struct(day);

    local dtotal = 0;
    local dipnum = 0;
    local tops = {};
    for i=1,24 do
        day.hour = i-1;
        local tmp,total,ipnum, topip, topcnt = Top.topday_hour(day);
        table.insert(tops,{hour=i-1, total=total, ipnum=ipnum, topip=topip, topcnt=topcnt });
        dtotal = dtotal + tonumber(total);
        dipnum = dipnum + tonumber(ipnum);
    end

    web:json{
        success = true,
        htmls = View("topday.html"){"locals",strDay=req.PARAMS.day},
    }
end

local  function top7(web,req)
    local start = os.time();
    local day = req.PARAMS.day;
    day = Util.timeStr2Struct(day);

    local time = os.time(day);
    local sDay = os.date("*t",time - (7)*24*60*60);
    day = os.date("*t",time-24*60*60);

    local total7 = 0;
    local ipnum7 = 0;
    local tops = {};

    for i=0,6 do 
        local dtotal = 0;
        local dipnum = 0;
        local dtopip = "";
        local dtopcnt = 0;
        
        local  thisDay = os.date("*t",time - (7-i)*24*60*60);

        for i=1,24 do
            thisDay.hour = i-1;
            local tmp,total,ipnum, topip, topcnt = Top.topday_hour(thisDay);
            dtotal = dtotal + tonumber(total);
            dipnum = dipnum + tonumber(ipnum);

            if topcnt > dtopcnt then 
                dtopip = topip;
                dtopcnt = topcnt;
            end
        end

        local str=string.format("%d-%d-%d",thisDay.year,thisDay.month,thisDay.day);
        table.insert(tops,{day=str, dtotal=dtotal, dipnum=dipnum, 
                            dtopip=dtopip, dtopcnt=dtopcnt });

        total7 = total7 + dtotal;
        ipnum7 = ipnum7 + dipnum;
    end

    print(start,os.time());
    web:json{
        success = true,
        htmls = View("top7.html"){
                    tops=tops,
                    total7=total7,
                    ipnum7=ipnum7,
                    sDay=string.format("%d-%d-%d",sDay.year,sDay.month,sDay.day),
                    eDay=string.format("%d-%d-%d",day.year,day.month,day.day),
                },
    }
    print("",os.time());
end

local function detail(web,req)
    local hour = req.PARAMS.hour;
    hour = Util.timeStr2Struct(hour);

    local rip = req.PARAMS.rip;

    local records = Top.ip_detail(hour,rip);

    web:json{
        success = true,
        htmls = View("ipdetail.html"){"locals",strHour=req.PARAMS.hour},
    }
end

local function upload( web, req)
    local file = Upload:process(web,req);

    web:json{
        success = true,
        text = file.path;
    }
end

URLS = {
    ['/'] = index,
    ['/index/'] = index,
    ['/top/'] = top,
    ['/retop/'] = retop,
    ['/topday'] = topday,
    ['/top7'] = top7,
    ['/import/'] = import,
    ['/clear/'] = clear,
    ['/detail/'] = detail,
    ['/upload/'] = upload,
}

