#include "Timer.h"
#include "cmsis_os2_ext.h"
module CounterSecond32C {
	provides interface Counter<TSecond, uint32_t>;
}
implementation {

	async command uint32_t Counter.get() {
		return osCounterGetSecond();
	}

	async command bool Counter.isOverflowPending() {
		return FALSE;
	}

	async command void Counter.clearOverflow() { }

}
