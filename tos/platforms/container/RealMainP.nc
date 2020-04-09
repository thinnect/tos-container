// Container RealMainP

#include "cmsis_os2.h"

osMutexId_t atomic_mutex;

module RealMainP @safe() {
	provides interface Boot;
	uses {
		interface Scheduler;
		interface Init as PlatformInit;
		interface Init as SoftwareInit;
	}
}
implementation {

	#warning "Container RealMainP"

	void container_boot(uint16_t tos_node_id) @C() @spontaneous() {
		osMutexAttr_t mutex_param = {.attr_bits = osMutexRecursive};
		atomic_mutex = osMutexNew(&mutex_param);

		atomic {
			TOS_NODE_ID = tos_node_id;

			platform_bootstrap();

			call Scheduler.init();

			call PlatformInit.init();
			while(call Scheduler.runNextTask());

			call SoftwareInit.init();
			while(call Scheduler.runNextTask());
	  	}

		__nesc_enable_interrupt();

		signal Boot.booted();
	}

	bool container_run() @C() @spontaneous() {
		return call Scheduler.runNextTask();
	}

	void container_destroy() @C() @spontaneous() {
		// TODO deinitialize platform
		// Probably quite difficult to actually cleanly do, but;
		//    timers
		//    radio
		//    let the task queue empty or kill the scheduler somehow?
		//    ... anything else?
		// delete the atomic_mutex
	}

	default command error_t PlatformInit.init() { return SUCCESS; }
	default command error_t SoftwareInit.init() { return SUCCESS; }
	default event void Boot.booted() { }

}
