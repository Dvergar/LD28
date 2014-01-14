package common.systems;

#if client
typedef Main = Client;
#end

#if server
typedef Main = Server;
#end