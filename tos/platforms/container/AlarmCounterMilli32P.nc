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

	extern uint32_t osCounterGetMilli() @C();
	extern void notify_resume_container() @C();

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

		atomic {
			for(i=0;i<ALARM_COUNT;i++) {
				timers[i] = osTimerNew(&timer_callback, osTimerOnce, &timers[i], NULL);
				alarm[i] = call Counter.get();
			}
		}
		return SUCCESS;
	}

	// -----

	void timer_callback(void* argument) @C() {
		atomic {
			uint8_t tmr = (argument - (void*)timers)/sizeof(void*);
			if(tmr >= ALARM_COUNT) {
				err1("tmr %"PRIu8, tmr);
			}
			signal Alarm.fired[tmr]();
		}
		notify_resume_container();
	}

	async command void Alarm.start[uint8_t tmr](uint32_t dt) {
		#ifdef ACM_DEBUG
			debug1("start[%"PRIu8"] %p %"PRIu32, tmr, timers[tmr], dt);
		#endif

		if(dt == 0) { // TODO special handling? use a task and call it from there?
			dt = 1; // osTimerStart does not accept 0
		}

		if (dt > 600000) {
			warn1("long tmr[%"PRIu8"] %"PRIu32, tmr, dt);
		}

		atomic {
			osStatus_t rslt;
			alarm[tmr] = call Counter.get() + dt;

			rslt = osTimerStart(timers[tmr], dt);
			if(rslt != osOK) {
				err1("tmr["PRIu8"] death %d", tmr, rslt);
			}
		}
	}

	async command void Alarm.stop[uint8_t tmr]() {
		atomic {
			if(osTimerIsRunning(timers[tmr])) {
				#ifdef ACM_DEBUG
					debug1("stp[%"PRIu8"] %p", tmr, timers[tmr]);
				#endif
				osTimerStop(timers[tmr]);
			}
		}
	}

	async command bool Alarm.isRunning[uint8_t tmr]() {
		atomic return osTimerIsRunning(timers[tmr]) == 1;
	}

	async command void Alarm.startAt[uint8_t tmr](uint32_t t0, uint32_t dt) {
		#ifdef ACM_DEBUG
			debug1("startAt[%"PRIu8"] %p %"PRIu32"+%"PRIu32, tmr, timers[tmr], t0, dt);
		#endif

		atomic {
			osStatus_t rslt;
			uint32_t now = call Counter.get();
			uint32_t passed = now - t0;
			uint32_t tdt = 1; // Minimal possible value accepted by osTimerStart

			if(passed < dt) {
				tdt = dt - passed;
			}

			if (tdt > 600000) {
				warn1("long tmr[%"PRIu8"] %"PRIu32, tmr, tdt);
			}

			alarm[tmr] = t0 + dt; // Does this make sense if this is in the past?

			rslt = osTimerStart(timers[tmr], tdt);
			if(rslt != osOK) {
				err1("tmr["PRIu8"] death %d", tmr, rslt);
			}
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
		return osCounterGetMilli();
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

