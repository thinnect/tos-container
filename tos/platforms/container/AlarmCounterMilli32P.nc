#include "Timer.h"
#include "cmsis_os2.h"
module AlarmCounterMilli32P {
	provides interface Init;
	provides interface Alarm<TMilli, uint32_t>[uint8_t timer];
	provides interface Counter<TMilli, uint32_t>;
}
implementation {

	#define __MODUUL__ "acm"
	#define __LOG_LEVEL__ ( LOG_LEVEL_AlarmCounterMilli32P & BASE_LOG_LEVEL )
	#include "log.h"

	extern uint32_t osCounterMilliGet() @C();

	enum {
		ALARM_COUNT = uniqueCount("AlarmMilli32C")
	};

	osTimerId_t timers[ALARM_COUNT];
	uint32_t alarm[ALARM_COUNT];

	void timer_callback(void* argument);

	command error_t Init.init() {
		uint8_t i;
		
		#ifdef ACM_DEBUG
			debug1("alarms %d", ALARM_COUNT);
		#endif

		for(i=0;i<ALARM_COUNT;i++) {
			atomic {
				timers[i] = osTimerNew(&timer_callback, osTimerOnce, &timers[i], NULL);
				alarm[i] = call Counter.get();
			}
		}
		return SUCCESS;
	}

	// -----

	void timer_callback(void* argument) @C() {
		uint8_t tmr = (argument - (void*)timers)/sizeof(void*);
		signal Alarm.fired[tmr]();
	}

	async command void Alarm.start[uint8_t tmr](uint32_t dt) {
		uint32_t ta = call Counter.get() + dt;

		#ifdef ACM_DEBUG
			debug1("start[%d] 0x%x %"PRIu32"+%"PRIu32, tmr, timers[tmr], ta - dt, dt);
		#endif

		if(dt == 0) { // TODO special handling? use a task and call it from there?
			dt = 1; // osTimerStart does not accept 0
		}

		atomic {
			alarm[tmr] = ta;
			osTimerStart(timers[tmr], dt);
		}
	}

	async command void Alarm.stop[uint8_t tmr]() {
		if(osTimerIsRunning(timers[tmr])) {
			
			#ifdef ACM_DEBUG
				debug1("stp[%d] 0x%x", tmr, timers[tmr]);
			#endif

			osTimerStop(timers[tmr]);
		}
	}

	async command bool Alarm.isRunning[uint8_t tmr]() {
		return osTimerIsRunning(timers[tmr]) == 1;
	}

	async command void Alarm.startAt[uint8_t tmr](uint32_t t0, uint32_t dt) {
		uint32_t ta = t0 + dt;

		#ifdef ACM_DEBUG
			debug1("startAt[%d] 0x%x %"PRIu32"+%"PRIu32, tmr, timers[tmr], t0, dt);
		#endif

		atomic {
			uint32_t tdt = ta - call Counter.get();
			if(tdt == 0) { // TODO special handling
				tdt = 1;
			}
			alarm[tmr] = ta;
			osTimerStart(timers[tmr], tdt);
		}
	}

	async command uint32_t Alarm.getNow[uint8_t tmr]() {
		return call Counter.get();
	}

	async command uint32_t Alarm.getAlarm[uint8_t tmr]() {
		uint32_t ta;
		atomic ta = alarm[tmr];
		return ta;
	}

	default async event void Alarm.fired[uint8_t tmr]() {}


	// -----

	async command uint32_t Counter.get() {
		return osCounterMilliGet();
	}

	async command bool Counter.isOverflowPending() {
		// TODO needs to be implemented, otherwise can run only for 48 days
		return FALSE;
	}

	async command void Counter.clearOverflow() {
		// TODO needs to be implemented, otherwise can run only for 48 days
	}

	// async event void Counter.overflow();

}

