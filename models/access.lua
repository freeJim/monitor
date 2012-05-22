module(..., package.seeall)

local Model = require 'bamboo.model'
local View = require 'bamboo.view'
local Util = require 'app.util'

local Access 
Access = Model:extend {
    __tag = 'Bamboo.Model.Access';
	__name = 'Access';
	__desc = 'Abstract Access node definition.';
--	__indexfd = 'title';
	__use_rule_index = false;
    __fields = {
		['host'] 			= {},
		['rip'] 			= {},
		['rport'] 			= {},
		['time'] 			= {},
		['method'] 			= {},
		['url'] 			= {},
		['version'] 			= {},
		['status'] 			= {},
		['size'] 			= {},
		['created_date'] 	= {},
		['last_modified_date'] 	= {},
		
	};

	
	init = function(self, t)
		if not t then 
            return self 
        end
		
        self.host   = t.host;
        self.rip    = t.rip;
        self.rport  = t.rport;
        self.time   = t.time;
        self.method = t.method;
        self.url    = t.url;
        self.version            = t.version;
        self.status             = t.status;
        self.size               = t.size;
        self.created_date       = os.time();
        self.last_modified_date = self.created_date;
		return self
	end;

    dump = function(self,count)
        count = count or 1;
        count = count-1;

        print("----------- Start Access -----------");
        print("id",self.id);
        print("host",self.host);
        print("rip",self.rip);
        print("rport",self.rport);
        print("time",self.time);
        print("method",self.method);
        print("url",self.url);
        print("version",self.version);
        print("status",self.status);
        print("size",self.size);
        print("created_date:",self.created_date);
        print("last_modified_date:",self.last_modified_date);

        if count > 0 then
        end

        print("----------- End Access -----------");
    end
}



return Access

