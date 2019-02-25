#include "Timer.h"
configuration AlarmCounterMilli32C {
	provides interface Alarm<TMilli, uint32_t>[uint8_t timer];
	provides interface Counter<TMilli, uint32_t>;
}
implementation {

	components AlarmCounterMilli32P;
	Alarm = AlarmCounterMilli32P;
	Counter = AlarmCounterMilli32P;

	components RealMainP;
	RealMainP.PlatformInit -> AlarmCounterMilli32P.Init;

}
