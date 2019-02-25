generic configuration AlarmMilli32C() {
	provides interface Alarm<TMilli, uint32_t>;
}
implementation {

	components AlarmCounterMilli32C;
	Alarm = AlarmCounterMilli32C.Alarm[unique("AlarmMilli32C")];

}
