configuration CounterMilli32C {
	provides interface Counter<TMilli, uint32_t>;
}
implementation {

	components AlarmCounterMilli32P;
	Counter = AlarmCounterMilli32P.Counter;

}
