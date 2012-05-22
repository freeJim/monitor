module(..., package.seeall)

local Model = require 'bamboo.model'
local View = require 'bamboo.view'
local Util = require 'app.util'

local IpCnt 
IpCnt = Model:extend {
    __tag = 'Bamboo.Model.IpCnt';
	__name = 'IpCnt';
	__desc = 'Abstract IpCnt node definition.';
--	__indexfd = 'title';
	__use_rule_index = false;
    __fields = {
		['ip'] 			= {},
		['cnt'] 			= {},
		['created_date'] 	= {},
		['last_modified_date'] 	= {},
	};

	
	init = function(self, t)
		if not t then 
            return self 
        end
		
        self.ip= t.ip;
        self.cnt    = t.cnt;
        self.created_date       = os.time();
        self.last_modified_date = self.created_date;
		return self
	end;

    dump = function(self,count)
        count = count or 1;
        count = count-1;

        print("----------- Start IpCnt -----------");
        print("id",self.id);
        print("ip",self.ip);
        print("cnt",self.cnt);
        print("created_date:",self.created_date);
        print("last_modified_date:",self.last_modified_date);

        if count > 0 then
        end

        print("----------- End IpCnt -----------");
    end
}



return IpCnt

