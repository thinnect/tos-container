module BusyWaitMicroC {
	provides interface BusyWait<TMicro,uint16_t>;
}
implementation {

	inline async command void BusyWait.wait(uint16_t dt) {
		// TODO
	}
}
