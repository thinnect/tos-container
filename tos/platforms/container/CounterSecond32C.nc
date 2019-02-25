#include "Timer.h"
module CounterSecond32C {
	provides interface Counter<TSecond, uint32_t>;
}
implementation {

	async command uint32_t Counter.get() {
		return 0;
	}

	async command bool Counter.isOverflowPending() {
		return FALSE;
	}

	async command void Counter.clearOverflow() { }

}
