#ifndef HARDWARE_H
#define HARDWARE_H

#include "cmsis_os2.h"

typedef uint8_t __nesc_atomic_t;
__nesc_atomic_t __nesc_atomic_start(void);
void __nesc_atomic_end(__nesc_atomic_t original);

#ifndef NESC_BUILD_BINARY

extern osMutexId_t atomic_mutex;

inline __nesc_atomic_t __nesc_atomic_start(void) @spontaneous() @safe() {
	// Acquire a recursive mutex initialized in container_boot
	while(osMutexAcquire(atomic_mutex, 1000) != osOK);
	return 0;
}

inline void __nesc_atomic_end(__nesc_atomic_t original) @spontaneous() @safe() {
	osMutexRelease(atomic_mutex);
}

inline void __nesc_enable_interrupt() @safe() {
	// TinyOS is not allowed to actually disable interrupts
}

inline void __nesc_disable_interrupt() @safe() {
	// TinyOS is not allowed to actually disable interrupts
}

// TODO wdt stuff needs cleanup
void wdt_reset() {}
void wdt_enable(uint16_t t) {}
void wdt_disable() {}

#endif//NESC_BUILD_BINARY

#endif//HARDWARE_H
