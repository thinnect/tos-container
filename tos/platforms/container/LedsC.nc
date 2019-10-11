module LedsC {
	provides {
		interface Init;
		interface Leds;
	}
}
implementation {

extern void PLATFORM_SetLed0() @C();
extern void PLATFORM_SetLed1() @C();
extern void PLATFORM_SetLed2() @C();
extern void PLATFORM_ClearLed0() @C();
extern void PLATFORM_ClearLed1() @C();
extern void PLATFORM_ClearLed2() @C();
extern void PLATFORM_ToggleLed0() @C();
extern void PLATFORM_ToggleLed1() @C();
extern void PLATFORM_ToggleLed2() @C();
extern PLATFORM_ToggleGpioPin (uint8_t pin_nr) @C();

	command error_t Init.init() {
		return SUCCESS;
	}

	async command void Leds.led0On() {
        PLATFORM_SetLed0();
	}

	async command void Leds.led0Off() {
        PLATFORM_ClearLed0();
	}

	async command void Leds.led0Toggle() {
        PLATFORM_ToggleLed0();
	}

	async command void Leds.led1On() {
        PLATFORM_SetLed1();
	}

	async command void Leds.led1Off() {
        PLATFORM_ClearLed1();
	}

	async command void Leds.led1Toggle() {
        PLATFORM_ToggleLed1();
	}

	async command void Leds.led2On() {
        PLATFORM_SetLed2();
	}

	async command void Leds.led2Off() {
        PLATFORM_ClearLed2();
	}

	async command void Leds.led2Toggle() {
        PLATFORM_ToggleLed2();
	}

	async command uint8_t Leds.get() {
		return 0;
	}

	async command void Leds.set(uint8_t val) {

	}

}
