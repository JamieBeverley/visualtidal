(
cmdPFunc = {

	// forward tidal messages to processing with addr: "/tidal"
	OSCdef(\visuals,{
		|msg|
		if(debug,{msg.postln;});
		msg[0] = '/tidal';
		visualsNetAddr.sendBundle(0,msg);
	},path:'/play2',recvPort:port);
	"adding visuals oscdef".postln;
};

cmdPFunc.value();
CmdPeriod.add(cmdPFunc);
);