#ifndef HARDWARE_H
#define HARDWARE_H

typedef uint8_t __nesc_atomic_t;
__nesc_atomic_t __nesc_atomic_start(void);
void __nesc_atomic_end(__nesc_atomic_t original);

#ifndef NESC_BUILD_BINARY

inline __nesc_atomic_t __nesc_atomic_start(void) @spontaneous() @safe() {
	// TODO
	return 0;
}

inline void __nesc_atomic_end(__nesc_atomic_t original_SREG) @spontaneous() @safe() {
	// TODO
}

inline void __nesc_enable_interrupt() @safe() {
	// TODO
}

inline void __nesc_disable_interrupt() @safe() {
	// TODO
}

// TODO wdt stuff needs cleanup
void wdt_reset() {}
void wdt_enable(uint16_t t) {}
void wdt_disable() {}

#endif//NESC_BUILD_BINARY

#endif//HARDWARE_H
