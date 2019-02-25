#include "hardware.h"
module PlatformP {
	provides interface Init;
	uses {
		interface Init as McuInit;
		interface Init as LedsInit;
		interface Init as SubInit;
	}
}
implementation {

	command error_t Init.init() {
		error_t ok;
		ok = call McuInit.init();
		ok = ecombine(ok, call LedsInit.init());
		ok = ecombine(ok, call SubInit.init());
		return ok;
	}

	default command error_t McuInit.init() {
		return SUCCESS;
	}

	default command error_t LedsInit.init() {
		return SUCCESS;
	}

	default command error_t SubInit.init() {
	return SUCCESS;
	}

}
