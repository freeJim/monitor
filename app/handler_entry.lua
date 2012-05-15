require 'bamboo'
Access = require 'models.access'
AccessHour = require 'models.accessHour'
IpCnt = require 'models.ipcnt'
Util = require 'app.util'

bamboo.registerModel(require 'models.access')
bamboo.registerModel(require 'models.accessHour')
bamboo.registerModel(require 'models.ipcnt')
bamboo.registerModule(require 'app.util')

local View = require 'bamboo.view'

local function index(web, req)
    web:page(View("index.html"){})

end

local function import(web,req)
    local filename = req.PARAMS.filename;
    local success, cnt = import_data(filename);
    if success then
        web:json{ success=true, cnt=cnt }
    else
        web:json{ success=false; }
    end

end

local function clear(web,req)
--    Access:all():del();

  --  web:json{ success= true };
end

local function top(web, req)
    local hour = req.PARAMS.hour;
    hour = Util.timeStr2Struct(hour);

    local top,total,ipnum = top_hour(hour);
    
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

    local top,total,ipnum = retop_hour(hour);
    
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
        local total,ipnum, topip, topcnt = topday_hour(day);
        table.insert(tops,{hour=i-1, total=total, ipnum=ipnum, topip=topip, topcnt=topcnt });
        dtotal = dtotal + tonumber(total);
        dipnum = dipnum + tonumber(ipnum);
    end

    web:json{
        success = true,
        htmls = View("topday.html"){"locals",strDay=req.PARAMS.day},
    }
end

local function detail(web,req)
    local hour = req.PARAMS.hour;
    hour = Util.timeStr2Struct(hour);

    local rip = req.PARAMS.rip;

    local records = ip_detail(hour,rip);

    web:json{
        success = true,
        htmls = View("ipdetail.html"){"locals",strHour=req.PARAMS.hour},
    }
end

URLS = {
    ['/'] = index,
    ['/index/'] = index,
    ['/top/'] = top,
    ['/retop/'] = retop,
    ['/topday'] = topday,
    ['/import/'] = import,
    ['/clear/'] = clear,
    ['/detail/'] = detail,
}

--77:5:lgcms,12:182.150.2.59,5:50940#10:1335489802#3:GET,1:/,8:HTTP/1.1,3:200#1:0#]
function parse(record)
    if record == nil then
        return nil;
    end

    local s,e = string.find(record,":");
    if s == nil then
        return nil;
    end

    local t = {};
    local len=0; 
    
    local  start = e+1;
    s,e = string.find(record,":",start);
    len = tonumber(string.sub(record,start,s-1));
    t.host = string.sub(record,e+1,e+len);

    start = e+1 + len+1;
    s,e = string.find(record,":",start);
    len = tonumber(string.sub(record,start,s-1));
    t.rip = string.sub(record,e+1,e+len);

    start = e+1 + len+1;
    s,e = string.find(record,":",start);
    len = tonumber(string.sub(record,start,s-1));
    t.rport = string.sub(record,e+1,e+len);

    start = e+1 + len+1;
    s,e = string.find(record,":",start);
    len = tonumber(string.sub(record,start,s-1));
    t.time = string.sub(record,e+1,e+len);

    start = e+1 + len+1;
    s,e = string.find(record,":",start);
    len = tonumber(string.sub(record,start,s-1));
    t.method = string.sub(record,e+1,e+len);

    start = e+1 + len+1;
    s,e = string.find(record,":",start);
    len = tonumber(string.sub(record,start,s-1));
    t.url = string.sub(record,e+1,e+len);

    start = e+1 + len+1;
    s,e = string.find(record,":",start);
    len = tonumber(string.sub(record,start,s-1));
    t.version = string.sub(record,e+1,e+len);

    start = e+1 + len+1;
    s,e = string.find(record,":",start);
    len = tonumber(string.sub(record,start,s-1));
    t.status = string.sub(record,e+1,e+len);

    start = e+1 + len+1;
    s,e = string.find(record,":",start);
    len = tonumber(string.sub(record,start,s-1));
    t.size = string.sub(record,e+1,e+len);

    return t;
end

function import_data(filename)

    local file = io.open("/home/free/" .. filename,"r");
    if file == nil then
        return false;
    end

    local cnt = 0;
    for line in file:lines() do
        local access = Access(parse(line));
        access:save();

        cnt = cnt +1;
        print(cnt);
    end
    io.close(file);

    return true,cnt
end

function top_ip_last(host,minutes)

end

--返回统计top100, 访问总次数，独立IP数
function retop_hour(hour)
    print("top_hour");
    local accessH = AccessHour:filter({ year=tostring(hour.year), 
                                        month=tostring(hour.month), 
                                        day=tostring(hour.day), 
                                        hour=tostring(hour.hour)})[1];
    
    if accessH == nil then--没有访问数据 
        return {}, 0;
    end

    --做IP——访问次数的HASH  
    local ip_count = {};
    local all = accessH:getForeign("accesses");
    for i,v in ipairs(all) do
        if ip_count[v.rip] == nil then 
            ip_count[v.rip] = 1;
        else
            ip_count[v.rip] = ip_count[v.rip] + 1;
        end
    end

    --top排序
    local top = {};
    for k,v in pairs(ip_count) do 
        table.insert(top,{rip=k,count=v});
    end
    table.sort(top,function(a,b) if a.count>b.count then return true end end);

    --更新TOP100
    accessH:deepClearForeign("top100");
    for i,v in ipairs(top) do
        if i<=100 then
            local ipcnt = IpCnt({ip=v.rip,cnt=v.count})
            ipcnt:save();
            accessH:addForeign("top100",ipcnt);
        end
    end

    --更新
    accessH.total = #all;
    accessH.ipnum = #top;
    accessH.topip = top[1].rip;
    accessH.topcnt= top[1].count;
    accessH:save();

    return accessH:getForeign("top100"),#all, #top, accessH.topip,accessH.topcnt;
end

--返回统计top100, 访问总次数，独立IP数
function top_hour(hour)
    print("top_hour");
    local accessH = AccessHour:filter({ year=tostring(hour.year), 
                                        month=tostring(hour.month), 
                                        day=tostring(hour.day), 
                                        hour=tostring(hour.hour)})[1];
    
    if accessH == nil then 
        return retop_hour(hour);
    end
    
    local top100 = accessH:getForeign("top100");
    if top100:isEmpty() then
        return retop_hour(hour);
    end

    return top100, accessH.total, accessH.ipnum, accessH.topip, accessH.topcnt;
end

--返回统计top100, 访问总次数，独立IP数
function topday_hour(hour)
    print("topday_hour");
    local accessH = AccessHour:filter({ year=tostring(hour.year), 
                                        month=tostring(hour.month), 
                                        day=tostring(hour.day), 
                                        hour=tostring(hour.hour)})[1];
    
    if accessH == nil then 
        return retop_hour(hour);
    end


    
    return accessH.total, accessH.ipnum, accessH.topip, accessH.topcnt;
end

function ip_detail(hour,rip)
    print("ipdetail",rip);

    local accessH = AccessHour:filter({ year=tostring(hour.year), 
                                        month=tostring(hour.month), 
                                        day=tostring(hour.day), 
                                        hour=tostring(hour.hour)})[1];
    
    if accessH == nil then 
        return {};
    end
    
    local all = accessH:getForeign("accesses");
    local records = {};
    for i,v in ipairs(all) do
        if v.rip == rip then 
            table.insert(records,v);
        end
    end

    return records;
end

function top_ip(startTime, endTime, host)
--    split_hour();
--[[    local ip_count = {};

    if startTime == nil then
        startTime = 0;
    end

    if endTime == nil then
        endTime = math.pow(2,63);
    end

    local all = nil;
    
    if host == nil then 
        all = Access:filter({time =be(startTime,endTime) });
    else
        all = Access:filter({host=host,time=be(startTime,endTime)});
    end

    for i,v in ipairs(all) do
        if ip_count[v.rip] == nil then 
            ip_count[v.rip] = 1;
        else
            ip_count[v.rip] = ip_count[v.rip] + 1;
        end
    end

    local top = {};
    for k,v in pairs(ip_count) do 
        table.insert(top,{rip=k,count=v});
    end

    table.sort(top,function(a,b) if a.count>b.count then return true end end);

    return top,#all,startTime,endTime;--]]
end

function write_to_file(filename, top, total, startTime, endTime)
    if filename == nil then
        filename = "/home/free/workspace/access.out";
    end

    local file = io.open(filename,"w");
    str = string.format("cnt:%d\ttotal:%d\tstartTime:%s\tendTime:%s\n"
                      ,#top,total,startTime,endtTime);
    file:write(str);
    for i,v in ipairs(ttt) do 
      local str = string.format("%s\t%d\n",v.rip,v.count);
      file:write(str);
    end
    io.close();
end

function split_hour()
--    local all = Access:all();

    local accessH = nil;        
--    for i,v in ipairs(all) do 
    for i=1,10000000000 do
        local v = Access:getById(i);

        print(i);
        if v == nil then 
            break;
        end

        local t = os.date("*t",v.time);
        t.year = tostring(t.year);
        t.month = tostring(t.month);
        t.day = tostring(t.day);
        t.hour = tostring(t.hour);

        if accessH == nil or accessH.year ~= (t.year) 
            or accessH.month ~= (t.month) or accessH.day ~= (t.day) 
            or accessH.hour ~= (t.hour) then
            accessH = AccessHour:filter({year=(t.year), month=(t.month), day=(t.day), hour=(t.hour)})[1];
            ptable(accessH);
        end

        if accessH == nil then
            accessH = AccessHour(t);
            accessH:save();
        end

        accessH:addForeign("accesses", v);
    end
end
