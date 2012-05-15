module(...,package.seeall)
Access = require 'models.access'
AccessHour = require 'models.accessHour'
IpCnt = require 'models.ipcnt'
Util = require 'app.util'
Upload = require 'bamboo.models.upload'

bamboo.registerModel(require 'models.access')
bamboo.registerModel(require 'models.accessHour')
bamboo.registerModel(require 'models.ipcnt')
bamboo.registerModule(require 'app.util')

local View = require 'bamboo.view'

--77:5:lgcms,12:182ll.150.2.59,5:50940#10:1335489802#3:GET,1:/,8:HTTP/1.1,3:200#1:0#]
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
    local file = io.open("media/uploads/" .. filename,"r");
    if file == nil then
        return false,"no such file [".."media/uploads/"..filename.."]";
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
        return {}, 0, 0, 0, 0;
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
    
    return {},accessH.total, accessH.ipnum, accessH.topip, accessH.topcnt;
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
            accessH = AccessHour:filter({year=(t.year), month=(t.month), 
                                        day=(t.day), hour=(t.hour)})[1];
        end

        if accessH == nil then
            accessH = AccessHour(t);
            accessH:save();
        end

        accessH:addForeign("accesses", v);
    end
end

--清除时段数据
function hour_clear(hour)
    print("hour_clear");
    local accessH = AccessHour:filter({ year=tostring(hour.year), 
                                        month=tostring(hour.month), 
                                        day=tostring(hour.day), 
                                        hour=tostring(hour.hour)})[1];
    
    if accessH == nil then 
        return false,"这个时段没有数据";
    end
    
    accessH:deepClearForeign("top100");
    accessH:deepClearForeign("accesses");
    accessH:del();

    return true;
end

