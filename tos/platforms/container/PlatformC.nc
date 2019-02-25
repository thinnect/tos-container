configuration PlatformC {
	provides {
		interface Init;
	}
	uses {
		interface Init as LedsInit;
		interface Init as SubInit;
	}
}
implementation {
	components PlatformP;

	Init = PlatformP;
	LedsInit = PlatformP.LedsInit;
	SubInit = PlatformP.SubInit;

}
