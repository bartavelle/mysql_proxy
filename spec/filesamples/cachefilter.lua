local tokenizer    = require("proxy.tokenizer")
local parser       = require("proxy.parser")
local commands     = require("proxy.commands")
local auto_config  = require("proxy.auto-config")

function log (level, message)
	local fh = io.open("/var/log/mysql-proxy/userlog.log", "a+")
	local text = "NULL"
	if message == nil then
		text = "NULL"
	else
		text = message
	end
	fh:write( string.format("%s %6d [%s] [%s] %s\n", os.date('%Y-%m-%d %H:%M:%S'), proxy.connection.server.thread_id, proxy.connection.client.default_db, level, text) )
	fh:close()
end

function Set (list)
	local set = {}
	for _, l in ipairs(list) do set[l] = true end
	return set
end

good_queries = Set { 
    "ROLLBACK ",
    "SELECT `*` FROM `table` ",
    "SELECT `*` FROM `user` WHERE `username` = ? ",
}

multiple_queries = Set {
    "SELECT `*` FROM `table` ",
}

function read_query(packet)
	local tpe = packet:byte()
	local cmd = commands.parse(packet)
	local qdesc = commands.pretty_print(cmd)
	local accept = false
	
	if	tpe==proxy.COM_SLEEP		then accept = true
	elseif	tpe==proxy.COM_QUIT 		then accept = true
	elseif	tpe==proxy.COM_INIT_DB 		then
	elseif	(tpe==proxy.COM_QUERY) or (tpe==proxy.COM_STMT_PREPARE) then
		if cmd.query ~= nil then
			local tokens     = assert(tokenizer.tokenize(cmd.query))
			local norm_query = string.gsub(tokenizer.normalize(tokens), ' NULL ', ' ? ')
			if( good_queries[norm_query] ) then
				proxy.queries:append(1, packet, { resultset_is_needed = true } )
				log("OK", qdesc)
				return proxy.PROXY_SEND_QUERY
			else
				print("BAD query : '" .. qdesc .. "' (format = '" .. norm_query .. "')")
				log("BAD", qdesc .. "[format='" .. norm_query .. "']")
				proxy.response = { type = proxy.MYSQLD_PACKET_ERR,
					errmsg = "Query '" .. cmd.query .. "' rejected",
					errno = 1205,
					sqlstate = "HY000" }
				return proxy.PROXY_SEND_RESULT
			end
		end
	elseif	tpe==proxy.COM_FIELD_LIST 	then
	elseif	tpe==proxy.COM_CREATE_DB 	then
	elseif	tpe==proxy.COM_DROP_DB 		then
	elseif	tpe==proxy.COM_REFRESH 		then
	elseif	tpe==proxy.COM_SHUTDOWN 	then
	elseif	tpe==proxy.COM_STATISTICS 	then
	elseif	tpe==proxy.COM_PROCESS_INFO 	then
	elseif	tpe==proxy.COM_CONNECT 		then
	elseif	tpe==proxy.COM_PROCESS_KILL 	then
	elseif	tpe==proxy.COM_DEBUG 		then
	elseif	tpe==proxy.COM_PING 		then accept = true
	elseif	tpe==proxy.COM_TIME 		then
	elseif	tpe==proxy.COM_DELAYED_INSERT 	then
	elseif	tpe==proxy.COM_CHANGE_USER 	then
	elseif	tpe==proxy.COM_BINLOG_DUMP 	then
	elseif	tpe==proxy.COM_TABLE_DUMP 	then
	elseif	tpe==proxy.COM_CONNECT_OUT 	then
	elseif	tpe==proxy.COM_REGISTER_SLAVE 	then
	elseif	tpe==proxy.COM_STMT_EXECUTE 	then
		accept = true
		--log("EXEC", packet:sub(2))
	elseif	tpe==proxy.COM_STMT_SEND_LONG_DATA 	then  accept = true
	elseif	tpe==proxy.COM_STMT_CLOSE 	then  accept = true
	elseif	tpe==proxy.COM_STMT_RESET 	then  accept = true
	elseif	tpe==proxy.COM_SET_OPTION 	then
	elseif	tpe==proxy.COM_STMT_FETCH 	then
	elseif	tpe==proxy.COM_DAEMON 		then
	elseif	tpe==proxy.COM_ERROR 		then
	else
	end

	if accept == false then
		if cmd.query == nil then
			desc = qdesc
		else
			desc = cmd.query
		end
		log("BAD:", desc)
		proxy.response = { type = proxy.MYSQLD_PACKET_ERR, 
			errmsg = "Query '" .. desc .. "' rejected (bad type)",
			errno = 1205,
			sqlstate = "HY000" }
		return proxy.PROXY_SEND_RESULT
	end
	
	log("OK", qdesc)
	proxy.queries:append(1, packet, { resultset_is_needed = true } )
	return proxy.PROXY_SEND_QUERY
end

function security_breach(qdesc, msg)
	print("ALERT '" .. qdesc .. "' (" .. msg .. ")")
	log("ALERT" .. msg, qdesc);
	proxy.response = { type = proxy.MYSQLD_PACKET_ERR, 
		errmsg = "Query " .. qdesc .. " produced a security warning",
		errno = 1206,
		sqlstate = "HY000" }
	return proxy.PROXY_SEND_RESULT
end

function read_query_result(inj)
	if not inj.resultset.rows then return end
	local cmd = commands.parse(inj.query)
	local qdesc = commands.pretty_print(cmd)
	local nb = 0
	local single_result = false
	--if multiple_queries[cmd.query] then single_result = false end
	for row in inj.resultset.rows do
		nb = nb + 1
		if (nb>1) and (single_result) then return security_breach(cmd.query, "too many fields") end
		for k,v in pairs(row) do 
			if v=='honeytoken' then 
				return security_breach(cmd.query, "honey token")
			end
		end
	end
end
