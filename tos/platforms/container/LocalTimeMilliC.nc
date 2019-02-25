#include "Timer.h"
configuration LocalTimeMilliC {
	provides interface LocalTime<TMilli>;
}
implementation {

	components CounterMilli32C;
	components new CounterToLocalTimeC(TMilli);

	CounterToLocalTimeC.Counter -> CounterMilli32C;
	LocalTime = CounterToLocalTimeC;

}
